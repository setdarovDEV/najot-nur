"""Push notification device tokens and broadcast records."""
from __future__ import annotations

import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import Platform, PushAudience


class PushToken(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "push_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    token: Mapped[str] = mapped_column(String(512), unique=True, nullable=False)
    platform: Mapped[Platform] = mapped_column(
        Enum(Platform, name="platform"), default=Platform.android
    )


class PushNotification(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "push_notifications"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    audience: Mapped[PushAudience] = mapped_column(
        Enum(PushAudience, name="push_audience"), default=PushAudience.all
    )
    # course id or user id depending on audience
    target_id: Mapped[uuid.UUID | None] = mapped_column()
    sent_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    sent_at: Mapped[object | None] = mapped_column(DateTime(timezone=True))
    delivered_count: Mapped[int | None] = mapped_column()
