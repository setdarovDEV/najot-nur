"""Admin & curator schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.enums import HomeworkStatus, PushAudience


class ClientRow(BaseModel):
    """Row in the admin 'clients' table."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str | None
    phone: str | None
    email: str | None
    is_verified: bool
    created_at: datetime
    city: str | None = None
    # latest speech analysis summary/score (joined)
    last_speech_score: int | None = None
    last_speech_summary: str | None = None


class ClientMapPoint(BaseModel):
    """A client's device location, for the admin map view."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str | None
    phone: str | None
    city: str | None = None
    region: str | None = None
    country: str | None = None
    latitude: float
    longitude: float


class HomeworkRow(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    lesson_id: uuid.UUID
    status: HomeworkStatus
    submission_text: str | None
    submission_url: str | None
    curator_score: int | None
    curator_feedback: str | None
    reviewed_at: datetime | None
    created_at: datetime
    # joined metadata for the curator list
    user_full_name: str | None = None
    user_phone: str | None = None
    lesson_title: str | None = None
    course_title: str | None = None
    lesson_video_url: str | None = None


class GradeRequest(BaseModel):
    score: int = Field(..., ge=0, le=100)
    feedback: str | None = None


class GiftCourseRequest(BaseModel):
    course_id: uuid.UUID
    admin_note: str | None = None


class PushCreate(BaseModel):
    title: str = Field(..., max_length=200)
    body: str
    audience: PushAudience = PushAudience.all
    target_id: uuid.UUID | None = None


class PushRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    body: str
    audience: PushAudience
    target_id: uuid.UUID | None
    sent_at: datetime | None
    delivered_count: int | None
    created_at: datetime


# ───────────────────── Curator management (admin only) ─────────────────────
class CuratorCreate(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=160)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class CuratorUpdate(BaseModel):
    full_name: str | None = Field(None, min_length=1, max_length=160)
    password: str | None = Field(None, min_length=6, max_length=128)
    is_active: bool | None = None


class CuratorRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str | None
    email: str | None
    is_active: bool
    is_verified: bool
    created_at: datetime
