"""Telegram bot webhook: register phone→chat_id mapping for OTP delivery."""
from __future__ import annotations

import hashlib
import hmac

from fastapi import APIRouter, Header, HTTPException, Request

from app.core.config import settings
from app.core.logging import get_logger
from app.core.redis_client import cache_set
from app.services.otp_service import TELEGRAM_CHAT_KEY

log = get_logger("telegram_webhook")
router = APIRouter()

TELEGRAM_API = "https://api.telegram.org/bot{token}"
# Store phone→chat_id for 30 days (user does not need to re-register each time).
CHAT_ID_TTL = 60 * 60 * 24 * 30

_WELCOME = (
    "Assalomu alaykum! 👋\n\n"
    "Telefon raqamingizni ulashing — shunda tasdiqlash kodlari shu chatga keladi."
)
_REGISTERED = "✅ Raqamingiz ro'yxatdan o'tdi. Endi tasdiqlash kodlari shu chatga yuboriladi."
_ALREADY = "Siz allaqachon ro'yxatdan o'tgansiz. Kodlar bu chatga keladi."


def _verify_secret(body: bytes, x_telegram_bot_api_secret_token: str | None) -> None:
    """Optional: verify Telegram's secret token header if configured."""
    secret = getattr(settings, "telegram_webhook_secret", "")
    if not secret:
        return
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, x_telegram_bot_api_secret_token or ""):
        raise HTTPException(status_code=403, detail="Invalid webhook secret")


async def _send(chat_id: int | str, text: str) -> None:
    import httpx

    if not settings.telegram_bot_token:
        return
    url = f"{TELEGRAM_API.format(token=settings.telegram_bot_token)}/sendMessage"
    async with httpx.AsyncClient(timeout=10) as client:
        await client.post(url, json={"chat_id": chat_id, "text": text})


async def _send_contact_request(chat_id: int | str) -> None:
    """Send a reply-keyboard button that requests the user's phone number."""
    import httpx

    if not settings.telegram_bot_token:
        return
    url = f"{TELEGRAM_API.format(token=settings.telegram_bot_token)}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": _WELCOME,
        "reply_markup": {
            "keyboard": [[{"text": "📱 Telefon raqamni ulashish", "request_contact": True}]],
            "resize_keyboard": True,
            "one_time_keyboard": True,
        },
    }
    async with httpx.AsyncClient(timeout=10) as client:
        await client.post(url, json=payload)


@router.post("/telegram/webhook")
async def telegram_webhook(
    request: Request,
    x_telegram_bot_api_secret_token: str | None = Header(default=None),
) -> dict:
    body = await request.body()
    _verify_secret(body, x_telegram_bot_api_secret_token)

    update: dict = await request.json()
    message = update.get("message") or update.get("edited_message")
    if not message:
        return {"ok": True}

    chat_id: int = message["chat"]["id"]
    contact = message.get("contact")
    text: str = message.get("text", "")

    if contact:
        # Foydalanuvchi telefon raqamini ulashdi
        phone = contact.get("phone_number", "").strip()
        if not phone.startswith("+"):
            phone = f"+{phone}"

        key = TELEGRAM_CHAT_KEY.format(phone=phone)
        existing = None
        from app.core.redis_client import cache_get, get_redis
        if get_redis() is not None:
            existing = await cache_get(key)

        await cache_set(key, str(chat_id), ttl=CHAT_ID_TTL)
        log.info("telegram_webhook.registered", phone=phone, chat_id=chat_id)

        reply = _ALREADY if existing else _REGISTERED
        await _send(chat_id, reply)
        return {"ok": True}

    if text.startswith("/start"):
        await _send_contact_request(chat_id)
        return {"ok": True}

    return {"ok": True}
