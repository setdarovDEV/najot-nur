"""JWT issuing/verification and password hashing."""
from __future__ import annotations

import asyncio
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

import bcrypt
import jwt

from app.core.config import settings

TokenType = Literal["access", "refresh"]


# ───────────────────── Passwords ─────────────────────
def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode(), hashed.encode())
    except (ValueError, TypeError):
        return False


# bcrypt is CPU-bound (~100-300ms); run it off the event loop in handlers.
async def hash_password_async(password: str) -> str:
    return await asyncio.to_thread(hash_password, password)


async def verify_password_async(password: str, hashed: str) -> bool:
    return await asyncio.to_thread(verify_password, password, hashed)


# ───────────────────── JWT ─────────────────────
def _create_token(
    subject: str | uuid.UUID,
    token_type: TokenType,
    expires_delta: timedelta,
    extra: dict[str, Any] | None = None,
) -> str:
    now = datetime.now(UTC)
    payload: dict[str, Any] = {
        "sub": str(subject),
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
        "jti": uuid.uuid4().hex,
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def create_access_token(
    subject: str | uuid.UUID, expire_minutes: int, extra: dict[str, Any] | None = None
) -> str:
    return _create_token(subject, "access", timedelta(minutes=expire_minutes), extra)


def create_refresh_token(subject: str | uuid.UUID, expire_days: int) -> str:
    return _create_token(subject, "refresh", timedelta(days=expire_days))


def decode_token(token: str) -> dict[str, Any]:
    """Decode and validate a JWT. Raises jwt.PyJWTError on failure."""
    return jwt.decode(
        token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm]
    )


def _token_ttl_for_role(role: str) -> tuple[int, int]:
    """(access_minutes, refresh_days) for a role. See config.py for rationale."""
    if role == "admin":
        return (
            settings.access_token_expire_minutes_admin,
            settings.refresh_token_expire_days_admin,
        )
    if role == "curator":
        return (
            settings.access_token_expire_minutes_curator,
            settings.refresh_token_expire_days_curator,
        )
    return (
        settings.access_token_expire_minutes_user,
        settings.refresh_token_expire_days_user,
    )


def issue_token_pair(subject: str | uuid.UUID, role: str) -> dict[str, Any]:
    access_minutes, refresh_days = _token_ttl_for_role(role)
    return {
        "access_token": create_access_token(
            subject, access_minutes, extra={"role": role}
        ),
        "refresh_token": create_refresh_token(subject, refresh_days),
        "token_type": "bearer",
        "expires_in": access_minutes * 60,
    }
