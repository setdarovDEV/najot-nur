"""Pydantic schemas for the security-session subsystem."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.models.security_session import SecurityEventType


# ────────── Inputs ──────────
class SessionStartIn(BaseModel):
    platform: str = Field(min_length=1, max_length=16, default="android")
    os_version: str | None = Field(default=None, max_length=64)
    app_version: str | None = Field(default=None, max_length=32)
    device_model: str | None = Field(default=None, max_length=128)
    device_id: str | None = Field(default=None, max_length=128)
    locale: str | None = Field(default=None, max_length=8)


class SessionHeartbeatIn(BaseModel):
    watermark_text: str | None = Field(default=None, max_length=160)


class SessionEndIn(BaseModel):
    reason: str | None = Field(default=None, max_length=64)


class SecurityEventIn(BaseModel):
    type: SecurityEventType
    payload: dict = Field(default_factory=dict)
    note: str | None = Field(default=None, max_length=512)


class SessionRecordingIn(BaseModel):
    kind: str = Field(default="audio", max_length=16)
    duration_sec: int = Field(default=0, ge=0)
    mime_type: str = Field(default="audio/m4a", max_length=64)
    note: str | None = Field(default=None, max_length=160)


# ────────── Outputs ──────────
class SessionOut(BaseModel):
    id: uuid.UUID
    is_active: bool
    started_at: datetime
    last_heartbeat_at: datetime | None
    ended_at: datetime | None
    platform: str
    os_version: str | None
    app_version: str | None
    device_model: str | None
    device_id: str | None
    locale: str | None
    country: str | None
    city: str | None
    watermark_text: str | None
    screen_capture_attempts: int
    screenshot_attempts: int
    auto_recordings_uploaded: int

    class Config:
        from_attributes = True


class SessionStartOut(BaseModel):
    """Returned on /sessions/start: contains everything the client needs to
    build the watermark and the protection state."""

    session: SessionOut
    watermark_text: str
    force_reauth: bool = False
    server_time: datetime


class EventOut(BaseModel):
    id: uuid.UUID
    type: SecurityEventType
    payload: dict
    note: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class SessionDetailOut(SessionOut):
    events: list[EventOut] = Field(default_factory=list)
