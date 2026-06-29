"""FastAPI dependencies: DB session, current user, role guards."""
from __future__ import annotations

import uuid
from typing import Annotated

import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.exceptions import ForbiddenError, UnauthorizedError
from app.core.security import decode_token
from app.models.enums import Role
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
        raise UnauthorizedError("Token muddati tugagan.") from exc
    except jwt.PyJWTError as exc:
        raise UnauthorizedError("Token yaroqsiz.") from exc

    if payload.get("type") != "access":
        raise UnauthorizedError("Noto'g'ri token turi.")

    user = await db.get(User, uuid.UUID(payload["sub"]))
    if user is None or not user.is_active:
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
        return await db.get(User, uuid.UUID(payload["sub"]))
    except Exception:
        return None


OptionalUser = Annotated[User | None, Depends(get_optional_user)]


def require_roles(*roles: Role):
    async def _guard(user: CurrentUser) -> User:
        if user.role not in roles:
            raise ForbiddenError("Bu amal uchun ruxsat yo'q.")
        return user

    return _guard


CuratorUser = Annotated[User, Depends(require_roles(Role.curator, Role.admin))]
AdminUser = Annotated[User, Depends(require_roles(Role.admin))]
