"""Authentication: phone OTP, Google, email/password, refresh."""
from __future__ import annotations

import uuid

import jwt
from fastapi import APIRouter, BackgroundTasks, Request
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession
from app.core.audit import audit_auth
from app.core.config import settings
from app.core.exceptions import ForbiddenError, UnauthorizedError
from app.core.metrics import auth_failures_total
from app.core.redis_client import cache_delete, cache_get, cache_set
from app.core.security import (
    decode_token,
    hash_password_async,
    issue_token_pair,
    verify_password_async,
)
from app.core.token_blacklist import blacklist_token, is_token_blacklisted
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
from app.services import amocrm, auth_service, sms
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


# ───────────────────── Phone OTP ─────────────────────

@router.post("/otp/request")
async def otp_request(payload: PhoneRequest) -> dict:
    """Step 1: telefon raqamga OTP kod yuboradi.

    Body dagi ``purpose`` maydoni (``registration`` yoki ``password_reset``)
    orqali SMS matni moderatsiyadan o'tgan matnga mos ravishda tanlanadi.
    """
    purpose = payload.purpose or "registration"
    if purpose not in ("registration", "password_reset"):
        purpose = "registration"

    code = await sms.send_otp(
        payload.phone, ttl=settings.otp_ttl_seconds, purpose=purpose
    )
    body: dict = {
        "sent": True,
        "ttl": settings.otp_ttl_seconds,
        "provider": settings.sms_provider,
        "purpose": purpose,
    }
    if settings.debug:
        body["dev_code"] = code
    return body


@router.post("/otp/check", response_model=OTPCheckResponse)
async def otp_check(payload: OTPCheckRequest) -> OTPCheckResponse:
    """Step 2: kodni tekshiradi va telefon raqamni tasdiqlanган deb belgilaydi."""
    valid = await sms.verify_otp(payload.phone, payload.code)
    if not valid:
        if not (settings.debug and payload.code == "000000"):
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
async def phone_login(
    payload: PhoneLoginRequest, request: Request, db: DbSession
) -> TokenPair:
    client_ip = (
        request.headers.get("X-Real-IP")
        or (request.headers.get("X-Forwarded-For") or "").split(",")[0].strip()
    )
    user_agent = request.headers.get("user-agent")

    user = (
        await db.execute(select(User).where(User.phone == payload.phone))
    ).scalar_one_or_none()
    if user is None or not user.is_active:
        auth_failures_total.labels(reason="invalid_credentials").inc()
        audit_auth(
            "login_failed", ip=client_ip, user_agent=user_agent,
            status="failed", reason="user_not_found",
        )
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
        auth_failures_total.labels(reason="no_password").inc()
        audit_auth(
            "login_failed", user_id=user.id, ip=client_ip, user_agent=user_agent,
            status="failed", reason="no_password_set",
        )
        raise UnauthorizedError("Bu hisob uchun parol o'rnatilmagan.")
    if not await verify_password_async(payload.password, identity.password_hash):
        auth_failures_total.labels(reason="wrong_password").inc()
        audit_auth(
            "login_failed", user_id=user.id, ip=client_ip, user_agent=user_agent,
            status="failed", reason="wrong_password",
        )
        raise UnauthorizedError("Telefon raqam yoki parol noto'g'ri.")

    audit_auth("login", user_id=user.id, ip=client_ip, user_agent=user_agent)
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
    if not phone_verified:
        raise UnauthorizedError("Kod noto'g'ri yoki muddati o'tgan.")
    await cache_delete(PHONE_VERIFIED_KEY.format(phone=payload.phone))

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
    identity.password_hash = await hash_password_async(payload.new_password)
    await db.flush()
    return _tokens_for(user)


@router.post("/otp/verify", response_model=AuthResult)
async def otp_verify(
    payload: OTPVerifyRequest, db: DbSession, bg: BackgroundTasks
) -> AuthResult:
    """Final step of registration: confirm the phone_verified flag from Redis
    (set by `/otp/check`) and create the user account.
    """
    phone_verified = await cache_get(PHONE_VERIFIED_KEY.format(phone=payload.phone))
    if not phone_verified:
        raise UnauthorizedError("Kod noto'g'ri yoki muddati o'tgan.")
    await cache_delete(PHONE_VERIFIED_KEY.format(phone=payload.phone))

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
                        password_hash=await hash_password_async(payload.password),
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
    name = user.full_name or user.email
    if "admin.notiqlik.uz" in origin and user.role != Role.admin:
        raise ForbiddenError(f"{name} — bu panel faqat adminlar uchun.")
    if "curator.notiqlik.uz" in origin and user.role != Role.curator:
        raise ForbiddenError(f"{name} — bu panel faqat kuratorlar uchun.")


@router.post("/login", response_model=TokenPair)
async def email_login(
    payload: EmailLoginRequest, request: Request, db: DbSession
) -> TokenPair:
    email = payload.email.lower()
    origin = request.headers.get("origin", "")
    client_ip = (
        request.headers.get("X-Real-IP")
        or (request.headers.get("X-Forwarded-For") or "").split(",")[0].strip()
    )
    user_agent = request.headers.get("user-agent")
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
        auth_failures_total.labels(reason="invalid_credentials").inc()
        audit_auth(
            "login_failed", ip=client_ip, user_agent=user_agent,
            status="failed", reason="identity_not_found",
        )
        raise UnauthorizedError("Email yoki parol noto'g'ri.")
    if not await verify_password_async(payload.password, identity.password_hash):
        auth_failures_total.labels(reason="wrong_password").inc()
        audit_auth(
            "login_failed", user_id=identity.user_id, ip=client_ip,
            user_agent=user_agent, status="failed", reason="wrong_password",
        )
        raise UnauthorizedError("Email yoki parol noto'g'ri.")

    user = await db.get(User, identity.user_id)
    if user is None or not user.is_active:
        auth_failures_total.labels(reason="user_inactive").inc()
        audit_auth(
            "login_failed", ip=client_ip, user_agent=user_agent,
            status="failed", reason="user_inactive",
        )
        raise UnauthorizedError("Hisob faol emas.")

    _check_panel_role(user, origin)
    audit_auth("login", user_id=user.id, ip=client_ip, user_agent=user_agent)
    return _tokens_for(user)


@router.get("/me", response_model=UserPublic)
async def me(user: CurrentUser) -> User:
    """Return the currently authenticated admin/curator (used by the web panel)."""
    return user


# ───────────────────── Refresh ─────────────────────
@router.post("/refresh", response_model=TokenPair)
async def refresh(payload: RefreshRequest, db: DbSession) -> TokenPair:
    """Rotating refresh: each call blacklists the refresh token it consumed
    and issues a brand-new pair. A stolen refresh token stops working the
    moment the legitimate client refreshes again; an active user who keeps
    opening the app effectively never has to re-login (sliding expiry).
    """
    try:
        data = decode_token(payload.refresh_token)
    except jwt.ExpiredSignatureError as exc:
        auth_failures_total.labels(reason="refresh_expired").inc()
        raise UnauthorizedError(
            "Refresh token muddati tugagan. Qayta login qiling."
        ) from exc
    except jwt.PyJWTError as exc:
        auth_failures_total.labels(reason="invalid_refresh").inc()
        raise UnauthorizedError("Refresh token yaroqsiz.") from exc
    if data.get("type") != "refresh":
        auth_failures_total.labels(reason="wrong_token_type").inc()
        raise UnauthorizedError("Noto'g'ri token turi.")

    jti = data.get("jti")
    if jti and await is_token_blacklisted(jti):
        auth_failures_total.labels(reason="refresh_reused").inc()
        raise UnauthorizedError("Refresh token bekor qilingan. Qayta login qiling.")

    user = await db.get(User, uuid.UUID(data["sub"]))
    if user is None or not user.is_active:
        auth_failures_total.labels(reason="user_inactive").inc()
        raise UnauthorizedError("Foydalanuvchi topilmadi.")

    exp = data.get("exp")
    if jti and exp:
        await blacklist_token(jti, exp)

    return _tokens_for(user)


# ───────────────────── Logout ─────────────────────
@router.post("/logout")
async def logout(request: Request, user: CurrentUser) -> dict:
    """Blacklist the current access token so it cannot be reused."""
    auth_header = request.headers.get("authorization", "")
    if auth_header.lower().startswith("bearer "):
        token = auth_header[7:].strip()
        try:
            payload = decode_token(token)
            jti = payload.get("jti")
            exp = payload.get("exp")
            if jti and exp:
                await blacklist_token(jti, exp)
        except jwt.PyJWTError:
            pass

    client_ip = (
        request.headers.get("X-Real-IP")
        or (request.headers.get("X-Forwarded-For") or "").split(",")[0].strip()
    )
    audit_auth(
        "logout",
        user_id=user.id,
        ip=client_ip,
        user_agent=request.headers.get("user-agent"),
    )
    return {"ok": True}
