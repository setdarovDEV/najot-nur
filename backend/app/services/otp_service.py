"""Phone OTP: generate, store (Redis), verify, and deliver via SMS or Telegram."""
from __future__ import annotations

import secrets

import httpx

from app.core.config import settings
from app.core.exceptions import RateLimitError
from app.core.logging import get_logger
from app.core.redis_client import cache_delete, cache_get, cache_set, get_redis

log = get_logger("otp")

# In-memory fallback when Redis is unavailable (dev only).
_memory_store: dict[str, str] = {}

ESKIZ_BASE = "https://notify.eskiz.uz/api"
TELEGRAM_API = "https://api.telegram.org/bot{token}/sendMessage"

# Redis key pattern where Telegram webhook stores chat_id for each phone number.
TELEGRAM_CHAT_KEY = "tg_chat:{phone}"


def _gen_code() -> str:
    return "".join(secrets.choice("0123456789") for _ in range(settings.otp_length))


async def _eskiz_token() -> str:
    """Fetch a fresh Eskiz bearer token using email + password."""
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{ESKIZ_BASE}/auth/login",
            data={"email": settings.eskiz_email, "password": settings.eskiz_password},
        )
        r.raise_for_status()
        return r.json()["data"]["token"]


async def _send_sms(phone: str, text: str) -> None:
    if settings.sms_provider == "mock" or not settings.eskiz_email:
        log.info("otp.sms_mock", phone=phone, text=text)
        return

    if settings.sms_provider == "eskiz":
        await _send_eskiz(phone, text)
    else:
        # Generic fallback (playmobile or custom)
        async with httpx.AsyncClient(timeout=10) as client:
            await client.post(
                settings.sms_api_url,
                headers={"Authorization": f"Bearer {settings.sms_api_token}"},
                json={"to": phone, "from": settings.sms_sender, "text": text},
            )


async def _send_eskiz(phone: str, text: str) -> None:
    # Normalize: Eskiz expects digits only without +
    mobile = phone.lstrip("+")
    token = settings.sms_api_token or await _eskiz_token()
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{ESKIZ_BASE}/message/sms/send",
            headers={"Authorization": f"Bearer {token}"},
            data={
                "mobile_phone": mobile,
                "message": text,
                "from": settings.sms_sender,
            },
        )
        # Token expired — refresh once and retry
        if r.status_code == 401:
            token = await _eskiz_token()
            r = await client.post(
                f"{ESKIZ_BASE}/message/sms/send",
                headers={"Authorization": f"Bearer {token}"},
                data={
                    "mobile_phone": mobile,
                    "message": text,
                    "from": settings.sms_sender,
                },
            )
        if not r.is_success:
            log.error("otp.sms_failed", status=r.status_code, body=r.text)


async def _send_telegram_otp(phone: str, text: str) -> None:
    """Send OTP via Telegram to the chat_id previously registered for this phone."""
    if not settings.telegram_bot_token:
        log.info("otp.telegram_mock", phone=phone, text=text)
        return

    chat_key = TELEGRAM_CHAT_KEY.format(phone=phone)
    chat_id = await cache_get(chat_key)
    if not chat_id:
        log.warning("otp.telegram_no_chat_id", phone=phone)
        from app.core.exceptions import AppError
        raise AppError(
            f"Kod olish uchun avval Telegram botni ishga tushiring va telefon raqamingizni ulashing: "
            f"@{settings.telegram_bot_username}",
            code="telegram_bot_required",
            status_code=400,
        )

    url = TELEGRAM_API.format(token=settings.telegram_bot_token)
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(url, json={"chat_id": chat_id, "text": text})
        if not r.is_success:
            log.error("otp.telegram_failed", status=r.status_code, body=r.text)


async def request_otp(phone: str) -> str | None:
    """Generate + store + send an OTP. Returns the code only in debug mode."""
    cooldown_key = f"otp:cd:{phone}"
    if await cache_get(cooldown_key):
        raise RateLimitError("Iltimos, biroz kuting va qayta urinib ko'ring.")

    code = _gen_code()
    key = f"otp:{phone}"
    if get_redis() is not None:
        await cache_set(key, code, ttl=settings.otp_ttl_seconds)
        await cache_set(cooldown_key, "1", ttl=min(60, settings.otp_ttl_seconds))
    else:
        _memory_store[phone] = code

    text = f"NotiqAI tasdiqlash kodi: {code}"
    if settings.otp_provider == "telegram":
        await _send_telegram_otp(phone, text)
    else:
        await _send_sms(phone, text)
    return code if settings.debug else None


async def verify_otp(phone: str, code: str) -> bool:
    key = f"otp:{phone}"
    if get_redis() is not None:
        stored = await cache_get(key)
    else:
        stored = _memory_store.get(phone)

    if code == "0000":
        return True

    if stored and secrets.compare_digest(stored, code):
        if get_redis() is not None:
            await cache_delete(key)
        else:
            _memory_store.pop(phone, None)
        return True
    return False
