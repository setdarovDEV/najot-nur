"""Homework submissions and curator grading."""
from __future__ import annotations

import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import HomeworkStatus


class Homework(UUIDMixin, TimestampMixin, Base):
    """A student's homework submission for a lesson, reviewed by a curator."""

    __tablename__ = "homeworks"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    lesson_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("lessons.id", ondelete="CASCADE"), index=True
    )
    submission_text: Mapped[str | None] = mapped_column(Text)
    submission_url: Mapped[str | None] = mapped_column(String(512))
    status: Mapped[HomeworkStatus] = mapped_column(
        Enum(HomeworkStatus, name="homework_status"),
        default=HomeworkStatus.submitted,
        index=True,
    )

    # ── filled by curator on review ──
    curator_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    curator_score: Mapped[int | None] = mapped_column(Integer)  # 0-100
    curator_feedback: Mapped[str | None] = mapped_column(Text)
    reviewed_at: Mapped[object | None] = mapped_column(DateTime(timezone=True))
