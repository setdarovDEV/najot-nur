"""Courses, lessons, post-lesson quizzes, enrollments and progress."""
from __future__ import annotations

import uuid

from sqlalchemy import (
    Boolean,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import EnrollmentStatus


class Course(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "courses"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    slug: Mapped[str] = mapped_column(String(220), unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text)
    cover_url: Mapped[str | None] = mapped_column(String(512))
    price: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    level: Mapped[str] = mapped_column(String(40), default="beginner")
    is_published: Mapped[bool] = mapped_column(Boolean, default=False, index=True)

    lessons: Mapped[list["Lesson"]] = relationship(
        back_populates="course",
        cascade="all, delete-orphan",
        order_by="Lesson.order_index",
    )


class Lesson(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "lessons"

    course_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    order_index: Mapped[int] = mapped_column(Integer, default=0)
    video_url: Mapped[str | None] = mapped_column(String(512))
    duration_sec: Mapped[int] = mapped_column(Integer, default=0)
    # voice-exercise lessons trigger the AI practice flow after watching
    is_voice_exercise: Mapped[bool] = mapped_column(Boolean, default=False)
    voice_exercise_prompt: Mapped[str | None] = mapped_column(Text)

    course: Mapped["Course"] = relationship(back_populates="lessons")
    questions: Mapped[list["LessonQuestion"]] = relationship(
        back_populates="lesson",
        cascade="all, delete-orphan",
        order_by="LessonQuestion.order_index",
    )


class LessonQuestion(UUIDMixin, Base):
    """A post-lesson quiz question (multiple choice)."""

    __tablename__ = "lesson_questions"

    lesson_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("lessons.id", ondelete="CASCADE"), index=True
    )
    question: Mapped[str] = mapped_column(Text, nullable=False)
    options: Mapped[list] = mapped_column(JSONB, default=list)  # ["A","B","C","D"]
    correct_index: Mapped[int] = mapped_column(Integer, default=0)
    order_index: Mapped[int] = mapped_column(Integer, default=0)

    lesson: Mapped["Lesson"] = relationship(back_populates="questions")


class Enrollment(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "enrollments"
    __table_args__ = (
        UniqueConstraint("user_id", "course_id", name="user_course"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    course_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"), index=True
    )
    status: Mapped[EnrollmentStatus] = mapped_column(
        Enum(EnrollmentStatus, name="enrollment_status"),
        default=EnrollmentStatus.active,
    )
    progress_pct: Mapped[int] = mapped_column(Integer, default=0)

    lesson_progress: Mapped[list["LessonProgress"]] = relationship(
        back_populates="enrollment", cascade="all, delete-orphan"
    )


class LessonProgress(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "lesson_progress"
    __table_args__ = (
        UniqueConstraint("enrollment_id", "lesson_id", name="enrollment_lesson"),
    )

    enrollment_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("enrollments.id", ondelete="CASCADE"), index=True
    )
    lesson_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("lessons.id", ondelete="CASCADE"), index=True
    )
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    # auto-grade from the quiz (0-100)
    auto_score: Mapped[int | None] = mapped_column(Integer)

    enrollment: Mapped["Enrollment"] = relationship(back_populates="lesson_progress")
