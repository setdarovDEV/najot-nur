"""Eskiz.uz orqali SMS yuborish servisi.

Foydalanish:
  from app.services.sms import send_otp

Sozlash (.env):
  SMS_PROVIDER=eskiz
  ESKIZ_EMAIL=sizning@email.uz
  ESKIZ_PASSWORD=parolingiz

Token avtomatik Redis'da keshlanadi (28 kun).
"""
from __future__ import annotations

import random
import string

import httpx

from app.core.config import settings
from app.core.exceptions import AppError
from app.core.logging import get_logger
from app.core.redis_client import cache_delete, cache_get, cache_set

log = get_logger("sms")

ESKIZ_BASE = "https://notify.eskiz.uz/api"
TOKEN_CACHE_KEY = "eskiz:token"
TOKEN_TTL = 60 * 60 * 24 * 28  # 28 kun

OTP_CACHE_KEY = "sms_otp:{phone}"


def _generate_code(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


async def _get_token() -> str:
    cached = await cache_get(TOKEN_CACHE_KEY)
    if cached:
        return cached

    if not settings.eskiz_email or not settings.eskiz_password:
        raise AppError(
            "Eskiz sozlanmagan. .env ga ESKIZ_EMAIL va ESKIZ_PASSWORD yozing.",
            code="eskiz_not_configured",
            status_code=503,
        )

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"{ESKIZ_BASE}/auth/login",
            data={
                "email": settings.eskiz_email,
                "password": settings.eskiz_password,
            },
        )
        if resp.status_code != 200:
            raise AppError(
                f"Eskiz login xatosi: {resp.text}",
                code="eskiz_auth_failed",
                status_code=502,
            )
        token: str = resp.json()["data"]["token"]

    await cache_set(TOKEN_CACHE_KEY, token, ttl=TOKEN_TTL)
    log.info("eskiz.token_refreshed")
    return token


async def _send_sms(phone: str, message: str) -> None:
    token = await _get_token()
    mobile = phone.lstrip("+")

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"{ESKIZ_BASE}/message/sms/send",
            data={
                "mobile_phone": mobile,
                "message": message,
                "from": settings.eskiz_sender,
                "callback_url": "",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        if resp.status_code == 401:
            # Token eskirgan — o'chirib qayta urinish
            await cache_delete(TOKEN_CACHE_KEY)
            token = await _get_token()
            resp = await client.post(
                f"{ESKIZ_BASE}/message/sms/send",
                data={
                    "mobile_phone": mobile,
                    "message": message,
                    "from": settings.eskiz_sender,
                    "callback_url": "",
                },
                headers={"Authorization": f"Bearer {token}"},
            )
        if resp.status_code not in (200, 201):
            raise AppError(
                f"SMS yuborishda xato: {resp.text}",
                code="sms_send_failed",
                status_code=502,
            )

    log.info("sms.sent", phone=phone)


_OTP_TEMPLATES = {
    "registration": "NotiqAI platformasida ro'yxatdan o'tish uchun tasdiqlash kodi: {code}",
    "password_reset": "NotiqAI platformasida parolni tiklash uchun tasdiqlash kodi: {code}",
}


async def send_otp(phone: str, ttl: int = 120, purpose: str = "registration") -> str:
    """6 xonali OTP kodni SMS orqali yuboradi va Redis'da saqlaydi.

    Args:
        phone: telefon raqami
        ttl: kodning amal qilish muddati (soniyalarda)
        purpose: "registration" yoki "password_reset" — qaysi xabar matnini
            ishlatishni belgilaydi. Moderatsiyadan o'tgan matnlar bilan bir xil.

    Returns:
        code — debug rejimida ishlatish uchun (production'da logga chiqmasin).
    """
    code = _generate_code(settings.otp_length)
    await cache_set(OTP_CACHE_KEY.format(phone=phone), code, ttl=ttl)

    template = _OTP_TEMPLATES.get(purpose, _OTP_TEMPLATES["registration"])
    message = template.format(code=code)

    if settings.sms_provider == "mock":
        log.info("sms.mock", phone=phone, purpose=purpose, code=code)
        return code

    await _send_sms(phone, message)
    return code


async def verify_otp(phone: str, code: str) -> bool:
    """Redis'da saqlangan OTP bilan tekshiradi. To'g'ri bo'lsa o'chiradi."""
    stored = await cache_get(OTP_CACHE_KEY.format(phone=phone))
    if not stored:
        return False
    if stored != code.strip():
        return False
    await cache_delete(OTP_CACHE_KEY.format(phone=phone))
    return True
