"""Quiz (test) model — curators create, admin approves, users take on mobile."""
from __future__ import annotations

import uuid

from sqlalchemy import Enum, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class Quiz(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "quizzes"

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    difficulty: Mapped[str] = mapped_column(String(20), default="medium")  # easy|medium|hard
    # [{question, options:[str], correct_index:int, explanation:str|None, image_url?:str, video_url?:str}]
    questions: Mapped[list] = mapped_column(JSONB, default=list)
    status: Mapped[str] = mapped_column(String(20), default="draft", index=True)  # draft|approved|rejected
    created_by_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    approved_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    category: Mapped[str | None] = mapped_column(String(80))
    cover_image_url: Mapped[str | None] = mapped_column(String(512))
    video_url: Mapped[str | None] = mapped_column(String(512))


class QuizAttempt(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "quiz_attempts"

    quiz_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("quizzes.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    answers: Mapped[list] = mapped_column(JSONB, default=list)  # [selected_index, ...]
    score: Mapped[int] = mapped_column(Integer, default=0)  # 0-100
    correct_count: Mapped[int] = mapped_column(Integer, default=0)
    total_count: Mapped[int] = mapped_column(Integer, default=0)
