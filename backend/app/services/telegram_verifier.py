"""Phone verification via Telegram's official "Login via Telegram" service.

When a user starts a registration flow, the backend calls `auth.sendCode`
through Telethon and Telegram sends a 6-digit code to the user's official
**"Verification Codes"** chat (the verified bot in their Telegram app —
visible at the top of every Telegram account). The user types the code
into our app, and we call `auth.signIn` to verify it.

The two endpoints are intentionally cheap and stateless: we never persist
the throwaway sessions we create, and the only thing the server keeps
between `send_code` and `check_code` is the `phone_code_hash`, stored
in Redis for a few minutes.

Setup
-----
1. Register an app at https://my.telegram.org → get `api_id` / `api_hash`.
2. Drop them into `.env` as `TELEGRAM_API_ID` / `TELEGRAM_API_HASH`.
3. Run ``python -m app.scripts.telegram_login`` once to authenticate the
   backend's working account and save the StringSession to
   `TELEGRAM_SESSION` in `.env`.
"""
from __future__ import annotations

import asyncio

from telethon import TelegramClient
from telethon.tl import types
from telethon.errors import (
    ApiIdInvalidError,
    FloodWaitError,
    PhoneCodeExpiredError,
    PhoneCodeInvalidError,
    PhoneNumberInvalidError,
    SessionPasswordNeededError,
)
from telethon.sessions import StringSession

from app.core.config import settings
from app.core.exceptions import AppError
from app.core.logging import get_logger
from app.core.redis_client import cache_delete, cache_get, cache_set

log = get_logger("telegram_verify")

# Redis key for the phone_code_hash returned by Telegram. We need it to
# verify the code, and we don't want the mobile client to see it.
HASH_KEY = "tg_verify:{phone}"
HASH_TTL_SECONDS = 300  # Telegram codes typically expire in ~5 minutes


def _check_configured() -> None:
    """Refuse to start if the operator hasn't finished Telegram setup."""
    if not settings.telegram_api_id or not settings.telegram_api_hash:
        raise AppError(
            "Telegram Login (Verification Codes) sozlanmagan. "
            ".env ga TELEGRAM_API_ID va TELEGRAM_API_HASH qo'ying.",
            code="telegram_login_not_configured",
            status_code=503,
        )


def _new_client() -> TelegramClient:
    """Build a one-shot Telethon client. We never persist this session."""
    return TelegramClient(
        StringSession(),
        settings.telegram_api_id,
        settings.telegram_api_hash,
        # Lower timeouts than Telethon's default 5-minute connect — we want
        # the mobile client to fail fast if Telegram is unreachable.
        connection_retries=2,
        retry_delay=1,
    )


async def send_code(phone: str) -> tuple[str, int]:
    """Ask Telegram to send a verification code to ``phone``.

    Returns ``(phone_code_hash, ttl_seconds)`` so the caller can store the
    hash in Redis and tell the user how long they have to enter the code.
    """
    _check_configured()
    client = _new_client()
    await client.connect()
    try:
        try:
            # Prefer in-app delivery to Telegram's official "Verification
            # Codes" chat over SMS. Telegram still falls back to SMS if the
            # account/device does not support in-app delivery.
            settings = types.CodeSettings(
                allow_app_hash=True,
                current_number=True,
                allow_firebase=False,
            )
            sent = await client.send_code_request(phone, settings=settings)
        except ApiIdInvalidError as exc:
            raise AppError(
                "Telegram api_id / api_hash noto'g'ri. "
                "https://my.telegram.org dan qayta oling.",
                code="telegram_api_invalid",
                status_code=503,
            ) from exc
        except PhoneNumberInvalidError as exc:
            raise AppError(
                "Telefon raqam noto'g'ri formatda.",
                code="phone_invalid",
                status_code=400,
            ) from exc
        except FloodWaitError as exc:
            # Telegram is rate-limiting us. Re-raise as 503 so the mobile
            # client knows to back off.
            raise AppError(
                f"Telegram juda ko'p so'rov qabul qildi. "
                f"{exc.seconds} soniyadan so'ng qayta urinib ko'ring.",
                code="telegram_flood_wait",
                status_code=503,
            ) from exc

        # Telegram returns a `timeout` (seconds) for the code; default to
        # our own TTL if it's missing.
        ttl = int(getattr(sent, "timeout", HASH_TTL_SECONDS) or HASH_TTL_SECONDS)
        await cache_set(
            HASH_KEY.format(phone=phone),
            sent.phone_code_hash,
            ttl=ttl,
        )
        log.info("telegram_verify.sent", phone=phone, ttl=ttl)
        return sent.phone_code_hash, ttl
    finally:
        await client.disconnect()


async def check_code(phone: str, code: str) -> bool:
    """Verify the code the user typed.

    Returns ``True`` if Telegram accepted the code, ``False`` if it was
    wrong or expired. Raises :class:`AppError` for any other failure
    (missing hash, server errors, 2FA-protected accounts, …).
    """
    _check_configured()

    phone_code_hash = await cache_get(HASH_KEY.format(phone=phone))
    if not phone_code_hash:
        # Hash expired or never existed → the user took too long.
        raise AppError(
            "Kod muddati o'tgan yoki yuborilmagan. Qaytadan urinib ko'ring.",
            code="telegram_code_expired",
            status_code=400,
        )

    client = _new_client()
    await client.connect()
    try:
        try:
            await client.sign_in(phone, code, phone_code_hash=phone_code_hash)
        except (PhoneCodeInvalidError, PhoneCodeExpiredError):
            log.info("telegram_verify.bad_code", phone=phone)
            return False
        except SessionPasswordNeededError:
            # The Telegram account the user is trying to verify has 2FA.
            # We can only confirm the *phone*; the code alone isn't enough.
            log.info("telegram_verify.2fa_blocked", phone=phone)
            raise AppError(
                "Bu telefon raqamda 2FA yoqilgan. "
                "Iltimos, boshqa raqam bilan urinib ko'ring.",
                code="telegram_2fa_required",
                status_code=400,
            )
        except FloodWaitError as exc:
            raise AppError(
                f"Telegram juda ko'p so'rov qabul qildi. "
                f"{exc.seconds} soniyadan so'ng qayta urinib ko'ring.",
                code="telegram_flood_wait",
                status_code=503,
            )
    finally:
        # Whatever the outcome, drop the throwaway session and the cached
        # hash so the code can't be reused.
        try:
            await client.log_out()
        except Exception:  # noqa: BLE001 — best effort
            pass
        await client.disconnect()
        await cache_delete(HASH_KEY.format(phone=phone))

    log.info("telegram_verify.verified", phone=phone)
    return True


# Exposed for tests / shutdown hooks.
def shutdown() -> None:
    """Cancel any background tasks. Currently a no-op (every call is
    self-contained inside its own event loop), but kept for future
    pooling."""
    return None


__all__ = ["send_code", "check_code", "shutdown"]


# Silence the unused-import warning for asyncio; kept around for future
# retry decorators.
_ = asyncio
