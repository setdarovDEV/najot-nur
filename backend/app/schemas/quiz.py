"""Quiz schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class QuizQuestion(BaseModel):
    question: str
    options: list[str] = Field(..., min_length=2, max_length=6)
    correct_index: int
    explanation: str | None = None
    image_url: str | None = None
    video_url: str | None = None


class QuizCreate(BaseModel):
    title: str = Field(..., max_length=255)
    description: str | None = None
    difficulty: str = Field("medium", pattern="^(easy|medium|hard)$")
    questions: list[QuizQuestion] = Field(..., min_length=1, max_length=50)
    category: str | None = Field(None, max_length=80)
    cover_image_url: str | None = Field(None, max_length=512)
    video_url: str | None = Field(None, max_length=512)


class QuizRead(BaseModel):
    id: uuid.UUID
    title: str
    description: str | None
    difficulty: str
    status: str
    category: str | None
    question_count: int
    created_at: datetime
    cover_image_url: str | None = None
    video_url: str | None = None

    model_config = {"from_attributes": True}


class QuizDetail(QuizRead):
    questions: list[dict]


class QuizAttemptCreate(BaseModel):
    answers: list[int]  # selected_index per question


class QuizAttemptRead(BaseModel):
    id: uuid.UUID
    quiz_id: uuid.UUID
    score: int
    correct_count: int
    total_count: int
    answers: list[int]
    created_at: datetime

    model_config = {"from_attributes": True}
