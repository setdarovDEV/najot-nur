"""Support chat schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SupportMessageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    text: str
    is_from_user: bool
    sent_by: uuid.UUID | None
    created_at: datetime


class SupportMessageCreate(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)


class SupportChatSummary(BaseModel):
    """One row per user in the admin chats list."""

    user_id: uuid.UUID
    full_name: str | None
    phone: str | None
    email: str | None
    last_message: str
    last_message_at: datetime
    unread_count: int
