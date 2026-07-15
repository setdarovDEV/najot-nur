"""FastAPI dependencies: DB session, current user, role guards."""
from __future__ import annotations

import uuid
from typing import Annotated

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.exceptions import ForbiddenError, UnauthorizedError
from app.core.metrics import auth_failures_total
from app.core.security import decode_token
from app.core.token_blacklist import is_token_blacklisted
from app.models.course import Enrollment
from app.models.enums import EnrollmentStatus, Role
from app.models.user import User

bearer = HTTPBearer(auto_error=False)

DbSession = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(
    db: DbSession,
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
) -> User:
    if creds is None:
        raise UnauthorizedError("Avtorizatsiya talab qilinadi.")
    try:
        payload = decode_token(creds.credentials)
    except jwt.ExpiredSignatureError as exc:
        auth_failures_total.labels(reason="token_expired").inc()
        raise UnauthorizedError("Token muddati tugagan.") from exc
    except jwt.PyJWTError as exc:
        auth_failures_total.labels(reason="invalid_token").inc()
        raise UnauthorizedError("Token yaroqsiz.") from exc

    if payload.get("type") != "access":
        auth_failures_total.labels(reason="wrong_token_type").inc()
        raise UnauthorizedError("Noto'g'ri token turi.")

    jti = payload.get("jti")
    if jti and await is_token_blacklisted(jti):
        auth_failures_total.labels(reason="token_blacklisted").inc()
        raise UnauthorizedError("Token bekor qilingan. Qayta login qiling.")

    user = await db.get(User, uuid.UUID(payload["sub"]))
    if user is None or not user.is_active:
        auth_failures_total.labels(reason="user_not_found").inc()
        raise UnauthorizedError("Foydalanuvchi topilmadi yoki bloklangan.")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


async def get_optional_user(
    db: DbSession,
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
) -> User | None:
    """Like get_current_user but returns None instead of raising — used to gate
    AI results behind registration without blocking anonymous browsing."""
    if creds is None:
        return None
    try:
        payload = decode_token(creds.credentials)
        if payload.get("type") != "access":
            return None
        jti = payload.get("jti")
        if jti and await is_token_blacklisted(jti):
            return None
        return await db.get(User, uuid.UUID(payload["sub"]))
    except Exception:
        return None


OptionalUser = Annotated[User | None, Depends(get_optional_user)]


async def get_enrolled_user(
    user: CurrentUser, db: DbSession
) -> User:
    """Faqat kamida bitta faol kursga yozilgan foydalanuvchilarga ruxsat.

    Adminlar va kuratorlar bundan mustasno (ular uchun kurs tekshirilmaydi).
    """
    if user.role in (Role.admin, Role.curator):
        return user

    has_enrollment = (
        await db.execute(
            select(Enrollment.id)
            .where(
                Enrollment.user_id == user.id,
                Enrollment.status == EnrollmentStatus.active,
            )
            .limit(1)
        )
    ).scalar_one_or_none()
    if has_enrollment is None:
        raise ForbiddenError(
            "Ushbu bo'limdan foydalanish uchun avval kurs sotib oling."
        )
    return user


EnrolledUser = Annotated[User, Depends(get_enrolled_user)]


def require_roles(*roles: Role):
    async def _guard(user: CurrentUser) -> User:
        if user.role not in roles:
            raise ForbiddenError("Bu amal uchun ruxsat yo'q.")
        return user

    return _guard


CuratorUser = Annotated[User, Depends(require_roles(Role.curator, Role.admin))]
AdminUser = Annotated[User, Depends(require_roles(Role.admin))]
