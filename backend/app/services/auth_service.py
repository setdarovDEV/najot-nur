"""Find-or-create users by external identity; link auth methods."""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import AuthProvider, Role
from app.models.user import AuthIdentity, User


async def get_or_create_by_identity(
    db: AsyncSession,
    *,
    provider: AuthProvider,
    provider_uid: str,
    full_name: str | None = None,
    email: str | None = None,
    phone: str | None = None,
    avatar_url: str | None = None,
) -> tuple[User, bool]:
    """Return (user, is_new). Creates a User + AuthIdentity on first sign-in."""
    stmt = select(AuthIdentity).where(
        AuthIdentity.provider == provider,
        AuthIdentity.provider_uid == provider_uid,
    )
    identity = (await db.execute(stmt)).scalar_one_or_none()
    if identity is not None:
        user = await db.get(User, identity.user_id)
        assert user is not None
        return user, False

    # Try to merge into an existing user with the same phone/email.
    user: User | None = None
    if phone:
        user = (
            await db.execute(select(User).where(User.phone == phone))
        ).scalar_one_or_none()
    if user is None and email:
        user = (
            await db.execute(select(User).where(User.email == email))
        ).scalar_one_or_none()

    is_new = user is None
    if user is None:
        user = User(
            full_name=full_name,
            phone=phone,
            email=email,
            avatar_url=avatar_url,
            role=Role.user,
            is_verified=provider in (AuthProvider.phone, AuthProvider.google),
        )
        db.add(user)
        await db.flush()

    db.add(
        AuthIdentity(
            user_id=user.id, provider=provider, provider_uid=provider_uid
        )
    )
    await db.flush()
    return user, is_new
