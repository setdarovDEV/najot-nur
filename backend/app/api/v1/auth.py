"""Authentication: phone OTP, Google, Telegram, email/password, refresh."""
from __future__ import annotations

import uuid

import jwt
from fastapi import APIRouter, BackgroundTasks, Request
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession
from app.core.config import settings
from app.core.exceptions import ForbiddenError, UnauthorizedError
from app.core.redis_client import cache_delete, cache_get, cache_set
from app.core.security import (
    decode_token,
    hash_password,
    issue_token_pair,
    verify_password,
)

from app.models.enums import AuthProvider, Role
from app.models.user import AuthIdentity, User
from app.schemas.auth import (
    AuthConfigResponse,
    AuthResult,
    EmailLoginRequest,
    GoogleAuthRequest,
    OTPCheckRequest,
    OTPCheckResponse,
    OTPVerifyRequest,
    PasswordResetRequest,
    PhoneExistsResponse,
    PhoneLoginRequest,
    PhoneRequest,
    RefreshRequest,
    TokenPair,
)
from app.schemas.user import UserPublic
from app.services import amocrm, auth_service, telegram_verifier
from app.services.oauth.google import verify_google_token

PHONE_VERIFIED_KEY = "phone_verified:{phone}"

router = APIRouter()


# ───────────────────── Public config ─────────────────────
@router.get("/config", response_model=AuthConfigResponse)
async def auth_config() -> AuthConfigResponse:
    """Non-secret auth settings the mobile client needs to render login UI.

    Public on purpose — only reveals provider identifiers (e.g. Google
    client id) that are already meant to be embedded in the public client.
    """
    return AuthConfigResponse(
        google_client_id=settings.google_client_id,
    )


def _tokens_for(user: User) -> TokenPair:
    return TokenPair(**issue_token_pair(user.id, user.role.value))


async def _maybe_push_lead(bg: BackgroundTasks, user: User, source: str) -> None:
    bg.add_task(
        amocrm.push_lead,
        full_name=user.full_name,
        phone=user.phone,
        email=user.email,
        source=source,
    )


# ───────────────────── Phone OTP (Telegram Verification Codes) ─────────────────────
@router.post("/otp/request")
async def otp_request(payload: PhoneRequest) -> dict:
    """Step 1 of the mobile registration flow: ask Telegram to send a
    6-digit code to the user's "Verification Codes" chat. The user types
    that code into the mobile app in step 2.
    """
    phone_code_hash, ttl = await telegram_verifier.send_code(payload.phone)
    body: dict = {
        "sent": True,
        "ttl": ttl,
        "provider": "telegram_verification_codes",
    }
    if settings.debug:
        # Never expose the actual code in production. We use the hash as a
        # debug-only sentinel so QA can confirm the request reached
        # Telegram without scraping the chat.
        body["dev_code_hash"] = phone_code_hash
    return body


@router.post("/otp/check", response_model=OTPCheckResponse)
async def otp_check(payload: OTPCheckRequest) -> OTPCheckResponse:
    """Step 2 of the mobile registration flow: verify the code against
    Telegram. If valid, mark the phone as verified in Redis so the final
    step (`/otp/verify`) can finish registration without calling Telegram
    again.
    """
    valid = await telegram_verifier.check_code(payload.phone, payload.code)
    if not valid:
        if not (settings.debug and payload.code == "0000"):
            raise UnauthorizedError("Kod noto'g'ri yoki muddati o'tgan.")

    await cache_set(
        PHONE_VERIFIED_KEY.format(phone=payload.phone),
        "1",
        ttl=settings.otp_ttl_seconds,
    )
    return OTPCheckResponse(valid=True, ttl=settings.otp_ttl_seconds)


@router.post("/phone/exists", response_model=PhoneExistsResponse)
async def phone_exists(payload: PhoneRequest, db: DbSession) -> PhoneExistsResponse:
    """Lightweight check: does this phone already have an account, and a password?"""
    user = (
        await db.execute(select(User).where(User.phone == payload.phone))
    ).scalar_one_or_none()
    if user is None:
        return PhoneExistsResponse(exists=False, has_password=False)

    has_pw = (
        await db.execute(
            select(AuthIdentity).where(
                AuthIdentity.user_id == user.id,
                AuthIdentity.provider == AuthProvider.password,
                AuthIdentity.password_hash.is_not(None),
            )
        )
    ).scalar_one_or_none() is not None
    return PhoneExistsResponse(exists=True, has_password=has_pw)


@router.post("/phone/login", response_model=TokenPair)
async def phone_login(payload: PhoneLoginRequest, db: DbSession) -> TokenPair:
    user = (
        await db.execute(select(User).where(User.phone == payload.phone))
    ).scalar_one_or_none()
    if user is None or not user.is_active:
        raise UnauthorizedError("Telefon raqam yoki parol noto'g'ri.")

    identity = (
        await db.execute(
            select(AuthIdentity).where(
                AuthIdentity.user_id == user.id,
                AuthIdentity.provider == AuthProvider.password,
            )
        )
    ).scalar_one_or_none()
    if identity is None or not identity.password_hash:
        raise UnauthorizedError("Bu hisob uchun parol o'rnatilmagan.")
    if not verify_password(payload.password, identity.password_hash):
        raise UnauthorizedError("Telefon raqam yoki parol noto'g'ri.")
    return _tokens_for(user)


@router.post("/password/reset", response_model=TokenPair)
async def reset_password(payload: PasswordResetRequest, db: DbSession) -> TokenPair:
    """Forgot-password: verify the code (or step-2 verified flag), then
    set (or overwrite) the password identity for the phone.
    Issues a fresh token pair on success.
    """
    user = (
        await db.execute(select(User).where(User.phone == payload.phone))
    ).scalar_one_or_none()
    if user is None or not user.is_active:
        raise UnauthorizedError("Telefon raqam yoki parol noto'g'ri.")

    phone_verified = await cache_get(PHONE_VERIFIED_KEY.format(phone=payload.phone))
    if phone_verified:
        await cache_delete(PHONE_VERIFIED_KEY.format(phone=payload.phone))
    else:
        valid = await telegram_verifier.check_code(payload.phone, payload.code)
        if not valid:
            if not (settings.debug and payload.code == "0000"):
                raise UnauthorizedError("Kod noto'g'ri yoki muddati o'tgan.")

    identity = (
        await db.execute(
            select(AuthIdentity).where(
                AuthIdentity.user_id == user.id,
                AuthIdentity.provider == AuthProvider.password,
            )
        )
    ).scalar_one_or_none()
    if identity is None:
        identity = AuthIdentity(
            user_id=user.id,
            provider=AuthProvider.password,
            provider_uid=payload.phone,
        )
        db.add(identity)
    identity.password_hash = hash_password(payload.new_password)
    await db.flush()
    return _tokens_for(user)


@router.post("/otp/verify", response_model=AuthResult)
async def otp_verify(
    payload: OTPVerifyRequest, db: DbSession, bg: BackgroundTasks
) -> AuthResult:
    """Final step of registration: the code was already verified in
    `/otp/check` (step 2). Here we just confirm the phone_verified flag
    from Redis and create the user.

    If the flag is missing (e.g. the client skipped `/otp/check`), we
    fall back to calling Telegram's `auth.signIn` as a safety net.
    """
    phone_verified = await cache_get(PHONE_VERIFIED_KEY.format(phone=payload.phone))
    if phone_verified:
        await cache_delete(PHONE_VERIFIED_KEY.format(phone=payload.phone))
    else:
        valid = await telegram_verifier.check_code(payload.phone, payload.code)
        if not valid:
            if not (settings.debug and payload.code == "0000"):
                raise UnauthorizedError("Kod noto'g'ri yoki muddati o'tgan.")

    full_name = payload.full_name
    if not full_name and (payload.first_name or payload.last_name):
        full_name = " ".join(
            x for x in (payload.first_name, payload.last_name) if x
        ).strip() or None

    user, is_new = await auth_service.get_or_create_by_identity(
        db,
        provider=AuthProvider.phone,
        provider_uid=payload.phone,
        phone=payload.phone,
        full_name=full_name,
    )
    if is_new:
        # Persist name + password (offer agreement) on the freshly created user
        if full_name and not user.full_name:
            user.full_name = full_name
        if payload.password:
            existing_pw = (
                await db.execute(
                    select(AuthIdentity).where(
                        AuthIdentity.user_id == user.id,
                        AuthIdentity.provider == AuthProvider.password,
                    )
                )
            ).scalar_one_or_none()
            if existing_pw is None:
                db.add(
                    AuthIdentity(
                        user_id=user.id,
                        provider=AuthProvider.password,
                        provider_uid=payload.phone,
                        password_hash=hash_password(payload.password),
                    )
                )
        await _maybe_push_lead(bg, user, "phone")
    return AuthResult(is_new_user=is_new, tokens=_tokens_for(user))


# ───────────────────── Google ─────────────────────
@router.post("/google", response_model=AuthResult)
async def google_auth(
    payload: GoogleAuthRequest, db: DbSession, bg: BackgroundTasks
) -> AuthResult:
    info = await verify_google_token(payload.id_token)
    user, is_new = await auth_service.get_or_create_by_identity(
        db,
        provider=AuthProvider.google,
        provider_uid=info["sub"],
        email=info.get("email"),
        full_name=info.get("name"),
        avatar_url=info.get("picture"),
    )
    if is_new:
        await _maybe_push_lead(bg, user, "google")
    return AuthResult(is_new_user=is_new, tokens=_tokens_for(user))


# ───────────────────── Email/password (admin & curators) ─────────────────────
_ADMIN_EMAIL = "admin@najotnur.uz"
_STAFF_DOMAIN = "@najotnur.uz"


def _check_email_format(email: str, origin: str) -> None:
    """Block obviously wrong emails before hitting the DB.

    curator.notiqlik.uz → must end with @najotnur.uz (fast reject for outsiders)
    No pre-auth block on admin panel — role check after auth returns 403.
    """
    if "curator.notiqlik.uz" in origin:
        if not email.endswith(_STAFF_DOMAIN):
            raise UnauthorizedError("Email yoki parol noto'g'ri.")


def _check_panel_role(user: User, origin: str) -> None:
    """After successful auth, verify role matches the panel → 403 if not."""
    if "admin.notiqlik.uz" in origin and user.role != Role.admin:
        raise ForbiddenError(f"{user.full_name or user.email} — bu panel faqat adminlar uchun.")
    if "curator.notiqlik.uz" in origin and user.role != Role.curator:
        raise ForbiddenError(f"{user.full_name or user.email} — bu panel faqat kuratorlar uchun.")


@router.post("/login", response_model=TokenPair)
async def email_login(
    payload: EmailLoginRequest, request: Request, db: DbSession
) -> TokenPair:
    email = payload.email.lower()
    origin = request.headers.get("origin", "")
    _check_email_format(email, origin)

    identity = (
        await db.execute(
            select(AuthIdentity).where(
                AuthIdentity.provider == AuthProvider.password,
                AuthIdentity.provider_uid == email,
            )
        )
    ).scalar_one_or_none()
    if identity is None or not identity.password_hash:
        raise UnauthorizedError("Email yoki parol noto'g'ri.")
    if not verify_password(payload.password, identity.password_hash):
        raise UnauthorizedError("Email yoki parol noto'g'ri.")

    user = await db.get(User, identity.user_id)
    if user is None or not user.is_active:
        raise UnauthorizedError("Hisob faol emas.")

    _check_panel_role(user, origin)
    return _tokens_for(user)


@router.get("/me", response_model=UserPublic)
async def me(user: CurrentUser) -> User:
    """Return the currently authenticated admin/curator (used by the web panel)."""
    return user


# ───────────────────── Refresh ─────────────────────
@router.post("/refresh", response_model=TokenPair)
async def refresh(payload: RefreshRequest, db: DbSession) -> TokenPair:
    try:
        data = decode_token(payload.refresh_token)
    except jwt.PyJWTError as exc:
        raise UnauthorizedError("Refresh token yaroqsiz.") from exc
    if data.get("type") != "refresh":
        raise UnauthorizedError("Noto'g'ri token turi.")

    user = await db.get(User, uuid.UUID(data["sub"]))
    if user is None or not user.is_active:
        raise UnauthorizedError("Foydalanuvchi topilmadi.")
    return _tokens_for(user)
