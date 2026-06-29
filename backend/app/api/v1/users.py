"""Current-user profile and device push-token registration."""
from __future__ import annotations

import uuid

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import or_, select
from sqlalchemy.dialects.postgresql import insert as pg_insert

from app.api.deps import CurrentUser, DbSession
from app.models.certificate import Certificate
from app.models.course import Course, Enrollment
from app.models.enums import Platform, PushAudience
from app.models.notification import PushNotification, PushToken
from app.schemas.common import Message
from app.schemas.user import UserRead, UserUpdate

router = APIRouter()


@router.get("/me", response_model=UserRead)
async def me(user: CurrentUser) -> UserRead:
    return UserRead.model_validate(user)


@router.patch("/me", response_model=UserRead)
async def update_me(payload: UserUpdate, user: CurrentUser, db: DbSession) -> UserRead:
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(user, field, value)
    await db.flush()
    return UserRead.model_validate(user)


@router.get("/me/certificates")
async def my_certificates(user: CurrentUser, db: DbSession) -> list[dict]:
    rows = (
        await db.execute(
            select(Certificate, Course)
            .join(Course, Certificate.course_id == Course.id)
            .where(Certificate.user_id == user.id)
            .order_by(Certificate.created_at.desc())
        )
    ).all()
    return [
        {
            "id": str(cert.id),
            "course_id": str(course.id),
            "course_title": course.title,
            "serial_number": cert.serial_number,
            "pdf_url": cert.pdf_url,
            "grade": cert.grade,
            "issued_at": cert.created_at.isoformat(),
        }
        for cert, course in rows
    ]


@router.get("/me/notifications")
async def my_notifications(user: CurrentUser, db: DbSession) -> list[dict]:
    """Push notifications targeted at this user (all, course, or user-specific)."""
    enrolled_ids = (
        await db.execute(select(Enrollment.course_id).where(Enrollment.user_id == user.id))
    ).scalars().all()
    rows = (
        await db.execute(
            select(PushNotification)
            .where(
                or_(
                    PushNotification.audience == PushAudience.all,
                    PushNotification.audience == PushAudience.user
                    and PushNotification.target_id == user.id,
                    *(
                        [
                            PushNotification.audience == PushAudience.course
                            and PushNotification.target_id.in_(enrolled_ids)
                        ]
                        if enrolled_ids
                        else []
                    ),
                )
            )
            .order_by(PushNotification.created_at.desc())
            .limit(50)
        )
    ).scalars().all()
    return [
        {
            "id": str(n.id),
            "title": n.title,
            "body": n.body,
            "audience": n.audience.value,
            "sent_at": n.sent_at.isoformat() if n.sent_at else None,
            "created_at": n.created_at.isoformat(),
        }
        for n in rows
    ]


class PushTokenRegister(BaseModel):
    token: str
    platform: Platform = Platform.android
    device_name: str | None = None
    app_version: str | None = None


@router.post("/me/push-token", response_model=Message)
async def register_push_token(
    payload: PushTokenRegister, user: CurrentUser, db: DbSession
) -> Message:
    # Upsert on the unique token; re-point it to this user if it moved devices.
    stmt = (
        pg_insert(PushToken)
        .values(
            user_id=user.id,
            token=payload.token,
            platform=payload.platform,
        )
        .on_conflict_do_update(
            index_elements=[PushToken.token],
            set_={
                "user_id": user.id,
                "platform": payload.platform,
            },
        )
    )
    await db.execute(stmt)
    return Message(message="Push token saqlandi.")


@router.get("/me/push-tokens", response_model=list[dict])
async def list_my_push_tokens(user: CurrentUser, db: DbSession) -> list[dict]:
    """Diagnostic endpoint — returns the device tokens registered for the
    current user. Useful for verifying the mobile app actually registered."""
    rows = (
        await db.execute(
            select(PushToken)
            .where(PushToken.user_id == user.id)
            .order_by(PushToken.created_at.desc())
        )
    ).scalars().all()
    return [
        {
            "id": str(t.id),
            "platform": t.platform.value,
            "token_preview": (t.token[:12] + "…") if len(t.token) > 12 else t.token,
            "created_at": t.created_at.isoformat(),
        }
        for t in rows
    ]
