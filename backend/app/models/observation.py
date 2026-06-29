"""Observation tests (psychology / body-language) and user attempts."""
from __future__ import annotations

import uuid

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import MediaType, ObservationCategory


class ObservationTest(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "observation_tests"

    order_index: Mapped[int] = mapped_column(Integer, default=0, index=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    prompt: Mapped[str] = mapped_column(Text, nullable=False)
    media_type: Mapped[MediaType] = mapped_column(
        Enum(MediaType, name="media_type"), default=MediaType.image
    )
    media_url: Mapped[str | None] = mapped_column(String(512))
    options: Mapped[list] = mapped_column(JSONB, default=list)
    # nullable: some tests are open-ended (AI-evaluated), no single correct option
    correct_option: Mapped[int | None] = mapped_column(Integer)
    category: Mapped[ObservationCategory] = mapped_column(
        Enum(ObservationCategory, name="observation_category"),
        default=ObservationCategory.observation,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)


class ObservationAttempt(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "observation_attempts"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    completed_at: Mapped[object | None] = mapped_column(DateTime(timezone=True))
    score: Mapped[int | None] = mapped_column(Integer)
    summary: Mapped[str | None] = mapped_column(Text)
    analysis: Mapped[dict | None] = mapped_column(JSONB)

    answers: Mapped[list["ObservationAnswer"]] = relationship(
        back_populates="attempt", cascade="all, delete-orphan"
    )


class ObservationAnswer(UUIDMixin, Base):
    __tablename__ = "observation_answers"

    attempt_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("observation_attempts.id", ondelete="CASCADE"), index=True
    )
    test_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("observation_tests.id", ondelete="CASCADE")
    )
    selected_option: Mapped[int | None] = mapped_column(Integer)
    answer_text: Mapped[str | None] = mapped_column(Text)
    is_correct: Mapped[bool | None] = mapped_column(Boolean)
    answered_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    attempt: Mapped["ObservationAttempt"] = relationship(back_populates="answers")
