"""User schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.enums import Role


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str | None
    phone: str | None
    email: str | None
    role: Role
    is_active: bool
    is_verified: bool
    avatar_url: str | None
    locale: str
    city: str | None = None
    region: str | None = None
    country: str | None = None
    pinfl: str | None = None
    created_at: datetime


class UserPublic(BaseModel):
    """Safe representation of the currently-authenticated user (admin/curator)."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    full_name: str | None
    email: str | None
    role: Role
    avatar_url: str | None


class UserUpdate(BaseModel):
    full_name: str | None = Field(None, max_length=160)
    email: EmailStr | None = None
    avatar_url: str | None = None
    locale: str | None = Field(None, max_length=5)
    city: str | None = Field(None, max_length=120)
    region: str | None = Field(None, max_length=120)
    country: str | None = Field(None, max_length=120)
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)
