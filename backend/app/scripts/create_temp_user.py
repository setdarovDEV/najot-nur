"""Idempotent helper: create a temporary phone+password user on the server.

Run from inside the backend container (or anywhere that has DATABASE_URL
pointing at the production DB):

    docker compose exec backend python -m app.scripts.create_temp_user

By default it creates the user described in the project README demo
section. Re-running is safe — it skips creation when a user with the
same phone already exists, and overwrites the password identity so the
login still works.

Override via env vars if you ever need a different temporary account:
    TEMP_USER_PHONE=900000000 TEMP_USER_PASSWORD=secret \
    TEMP_USER_FULL_NAME="Test User" \
    docker compose exec backend python -m app.scripts.create_temp_user
"""
from __future__ import annotations

import asyncio
import os

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.core.logging import configure_logging, get_logger
from app.core.security import hash_password
from app.models.enums import AuthProvider, Role
from app.models.user import AuthIdentity, User

log = get_logger("create_temp_user")

DEFAULT_PHONE = "953271309"
DEFAULT_PASSWORD = "abbos123"
DEFAULT_FULL_NAME = "Setdarov Abbos"


async def main() -> None:
    configure_logging()

    phone = os.environ.get("TEMP_USER_PHONE", DEFAULT_PHONE).strip()
    password = os.environ.get("TEMP_USER_PASSWORD", DEFAULT_PASSWORD)
    full_name = os.environ.get("TEMP_USER_FULL_NAME", DEFAULT_FULL_NAME).strip()

    if not phone or not password or not full_name:
        raise SystemExit(
            "TEMP_USER_PHONE, TEMP_USER_PASSWORD, TEMP_USER_FULL_NAME "
            "bosh bo'lmasligi kerak."
        )

    async with AsyncSessionLocal() as db:
        existing = (
            await db.execute(select(User).where(User.phone == phone))
        ).scalar_one_or_none()

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
            user.is_active = True
            user.is_verified = True
            log.info("temp_user.updated", user_id=str(user.id), phone=phone)

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
