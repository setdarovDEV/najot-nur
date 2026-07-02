"""Practicum schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PracticumCreate(BaseModel):
    title: str = Field(..., max_length=255)
    description: str | None = None
    category: str | None = Field(None, max_length=80)
    expert_text: str | None = None
    is_free: bool = True
    price: float = Field(0, ge=0)


class PracticumRead(BaseModel):
    id: uuid.UUID
    title: str
    description: str | None
    category: str | None
    expert_text: str | None
    expert_audio_url: str | None
    expert_transcript: str | None = None
    is_free: bool
    price: float
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class PracticumSubmissionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    practicum_id: uuid.UUID
    audio_url: str | None
    transcript: str | None
    overall_score: int | None
    status: str
    created_at: datetime
    # joined metadata for the curator list
    user_full_name: str | None = None
    user_phone: str | None = None
    # voice analysis fields (flattened for convenience):
    accuracy_score: int | None = None
    word_errors: list | None = None
    word_analysis: list | None = None
    char_stats: dict | None = None
    phoneme_errors: list | None = None
    summary: str | None = None
    reference_text: str | None = None
