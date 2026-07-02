"""Idempotent helper: create a temporary phone+password user on the server.

Run from inside the backend container (or anywhere that has DATABASE_URL
pointing at the production DB):

    docker compose exec backend python -m app.scripts.create_temp_user

The phone is normalised to E.164 ``+998XXXXXXXXX`` (12 digits) — the
exact format the mobile app sends in ``/auth/phone/login`` (see
``mobile/lib/core/utils/phone_formatter.dart``). Re-running is safe: if a
user with the same local 9 digits already exists in any format
(``953271309`` or ``+998953271309``) it is updated and the password
identity is reset. Any old-format row is migrated to ``+998...``.

Override via env vars if you ever need a different temporary account:
    TEMP_USER_PHONE=900000000 TEMP_USER_PASSWORD=secret \\
    TEMP_USER_FULL_NAME="Test User" \\
    docker compose exec backend python -m app.scripts.create_temp_user
"""
from __future__ import annotations

import asyncio
import os

from sqlalchemy import or_, select

from app.core.database import AsyncSessionLocal
from app.core.logging import configure_logging, get_logger
from app.core.security import hash_password
from app.models.enums import AuthProvider, Role
from app.models.user import AuthIdentity, User

log = get_logger("create_temp_user")

DEFAULT_PHONE = "953271309"
DEFAULT_PASSWORD = "abbos123"
DEFAULT_FULL_NAME = "Setdarov Abbos"
UZ_PREFIX = "+998"


def _normalize_phone(raw: str) -> tuple[str, str]:
    """Return ``(e164_phone, local_9_digits)``.

    E.164 ``+998XXXXXXXXX`` is what the mobile app sends. We also keep
    the bare 9-digit local part so we can locate a legacy row that was
    created in an earlier run without the country prefix.
    """
    digits = "".join(c for c in raw if c.isdigit())
    if not digits:
        raise SystemExit(f"Telefon raqamda raqam topilmadi: {raw!r}")
    if digits.startswith("998") and len(digits) >= 12:
        local = digits[3:12]
    else:
        local = digits[-9:] if len(digits) >= 9 else digits.zfill(9)
    if len(local) != 9:
        raise SystemExit(
            f"Telefon raqam 9 ta raqamdan iborat bo'lishi kerak: {raw!r}"
        )
    return f"{UZ_PREFIX}{local}", local


async def main() -> None:
    configure_logging()

    phone, local = _normalize_phone(
        os.environ.get("TEMP_USER_PHONE", DEFAULT_PHONE).strip()
    )
    password = os.environ.get("TEMP_USER_PASSWORD", DEFAULT_PASSWORD)
    full_name = os.environ.get("TEMP_USER_FULL_NAME", DEFAULT_FULL_NAME).strip()

    if not password or not full_name:
        raise SystemExit(
            "TEMP_USER_PASSWORD va TEMP_USER_FULL_NAME bosh bo'lmasligi kerak."
        )

    async with AsyncSessionLocal() as db:
        # Find any existing user for this phone in any of the known formats
        # so a previous run (which stored "953271309") gets migrated cleanly.
        candidates = {phone, local, f"+{local}"}
        existing = (
            await db.execute(select(User).where(User.phone.in_(candidates)))
        ).scalars().first()

        if existing is None:
            user = User(
                full_name=full_name,
                phone=phone,
                role=Role.user,
                is_verified=True,
                is_active=True,
            )
            db.add(user)
            await db.flush()
            log.info("temp_user.created", user_id=str(user.id), phone=phone)
        else:
            user = existing
            user.full_name = full_name
            user.phone = phone  # migrate to E.164
            user.is_active = True
            user.is_verified = True
            log.info(
                "temp_user.updated",
                user_id=str(user.id),
                old_phone=existing.phone,
                new_phone=phone,
            )

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
                provider_uid=phone,
            )
            db.add(identity)
        else:
            identity.provider_uid = phone  # keep the lookup key in sync
        identity.password_hash = hash_password(password)

        await db.commit()
        log.info(
            "temp_user.done",
            phone=phone,
            full_name=full_name,
        )
        print(
            f"✅ Tayyor. Telefon: {phone} | Ism: {full_name} | "
            f"Parol o'rnatildi (uzunligi: {len(password)})."
        )


if __name__ == "__main__":
    asyncio.run(main())
