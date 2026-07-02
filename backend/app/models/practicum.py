"""Practicum model — curator creates, admin approves, users listen on mobile."""
from __future__ import annotations

import uuid

from sqlalchemy import Boolean, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class Practicum(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "practicums"

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    category: Mapped[str | None] = mapped_column(String(80))
    expert_text: Mapped[str | None] = mapped_column(Text)
    expert_audio_url: Mapped[str | None] = mapped_column(String(512))
    # Auto-generated STT transcript of ``expert_audio_url`` (cached so the
    # per-submission analysis pipeline doesn't re-transcribe the same audio).
    expert_transcript: Mapped[str | None] = mapped_column(Text)
    is_free: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    price: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    status: Mapped[str] = mapped_column(String(20), default="draft", index=True)  # draft|approved|rejected
    created_by_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    approved_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
