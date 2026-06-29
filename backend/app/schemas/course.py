"""Course / lesson / enrollment schemas."""
from __future__ import annotations

import uuid
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import EnrollmentStatus


class LessonQuestionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    question: str
    options: list
    order_index: int
    # correct_index intentionally hidden from clients


class LessonRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    description: str | None
    order_index: int
    video_url: str | None
    duration_sec: int
    is_voice_exercise: bool
    voice_exercise_prompt: str | None


class CourseRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    slug: str
    description: str | None
    cover_url: str | None
    price: Decimal
    level: str
    is_published: bool


class CourseDetail(CourseRead):
    lessons: list[LessonRead] = []


class QuizSubmitRequest(BaseModel):
    lesson_id: uuid.UUID
    # answer index per question id
    answers: dict[uuid.UUID, int]


class QuizResult(BaseModel):
    score: int = Field(..., ge=0, le=100)
    correct: int
    total: int
    passed: bool


class EnrollmentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    course_id: uuid.UUID
    status: EnrollmentStatus
    progress_pct: int
