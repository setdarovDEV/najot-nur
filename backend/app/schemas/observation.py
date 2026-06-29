"""Observation test schemas."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict

from app.models.enums import MediaType, ObservationCategory


class ObservationTestRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    order_index: int
    title: str
    prompt: str
    media_type: MediaType
    media_url: str | None
    options: list
    category: ObservationCategory
    # NOTE: correct_option intentionally omitted from the public read schema


class ObservationAnswerInput(BaseModel):
    test_id: uuid.UUID
    selected_option: int | None = None
    answer_text: str | None = None


class ObservationSubmitRequest(BaseModel):
    answers: list[ObservationAnswerInput]


class ObservationAttemptRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    score: int | None
    summary: str | None
    analysis: dict | None
    completed_at: datetime | None
    created_at: datetime


# ───── AI-generated tests ─────

class GenerateTestRequest(BaseModel):
    difficulty: Literal["easy", "medium", "hard"] = "medium"


class GeneratedTest(BaseModel):
    id: str
    order_index: int
    title: str
    prompt: str
    category: str
    options: list[str]
    media_type: str = "image"
    media_url: str | None = None


class GeneratedSessionResponse(BaseModel):
    session_id: str
    tests: list[GeneratedTest]


class AiAnswerInput(BaseModel):
    test_id: str
    selected_option: int | None = None


class AiSubmitRequest(BaseModel):
    session_id: str
    answers: list[AiAnswerInput]
