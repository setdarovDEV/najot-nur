"""Audiobook schemas."""
from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class AudiobookPageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    page_number: int
    content: str | None
    audio_url: str | None


class AudiobookRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    author: str | None
    slug: str
    cover_url: str | None
    audio_url: str | None
    description: str | None
    category: str | None
    is_free: bool
    price: Decimal
    total_pages: int
    is_published: bool = False


class AudiobookDetail(AudiobookRead):
    pages: list[AudiobookPageRead] = []


class AudiobookCreate(BaseModel):
    title: str = Field(..., max_length=200)
    author: str | None = None
    description: str | None = None
    category: str | None = None
    is_free: bool = True
    price: Decimal = Decimal(0)
    cover_url: str | None = None


class AudiobookUpdate(BaseModel):
    title: str | None = Field(None, max_length=200)
    author: str | None = None
    description: str | None = None
    category: str | None = None
    is_free: bool | None = None
    price: Decimal | None = None


class AudiobookPageUpsert(BaseModel):
    page_number: int = Field(..., ge=1)
    content: str | None = None
    audio_url: str | None = None


class ProgressUpdate(BaseModel):
    current_page: int = Field(..., ge=1)


class AccessStatus(BaseModel):
    """Per-user access state for a (paid) audiobook."""

    state: Literal["granted", "locked"]
    reason: Literal["free", "purchased", "pending", "none"] = "none"
    has_pending_order: bool = False
