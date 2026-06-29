"""User voice submission for a practicum exercise."""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class PracticumSubmission(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "practicum_submissions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    practicum_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("practicums.id", ondelete="CASCADE"), index=True
    )
    audio_url: Mapped[str | None] = mapped_column(String(512))
    transcript: Mapped[str | None] = mapped_column(Text)
    voice_analysis_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("voice_analyses.id", ondelete="SET NULL"), nullable=True
    )
    overall_score: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(
        String(20), default="pending", index=True
    )  # pending|done|failed
