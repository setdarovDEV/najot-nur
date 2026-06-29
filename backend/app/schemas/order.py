"""Order schemas — manual payment zayavka for courses and audiobooks."""
from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models.enums import OrderPaymentMethod, OrderPurpose, OrderStatus


class OrderCreate(BaseModel):
    """Mobile payload — exactly one of course_id or audiobook_id must be set."""

    purpose: OrderPurpose
    course_id: uuid.UUID | None = None
    audiobook_id: uuid.UUID | None = None
    amount: Decimal = Field(..., gt=0, description="To'lov miqdori (UZS)")
    payment_method: OrderPaymentMethod
    payment_proof_url: str | None = Field(None, description="To'lov cheki screenshot URL")

    @model_validator(mode="after")
    def _exactly_one_target(self) -> "OrderCreate":
        if (self.course_id is None) == (self.audiobook_id is None):
            raise ValueError(
                "Faqat bitta maqsad ko'rsatilishi kerak: course_id yoki audiobook_id."
            )
        if self.purpose == OrderPurpose.course and self.course_id is None:
            raise ValueError("purpose='course' bo'lsa, course_id kerak.")
        if self.purpose == OrderPurpose.audiobook and self.audiobook_id is None:
            raise ValueError("purpose='audiobook' bo'lsa, audiobook_id kerak.")
        return self


class _OrderTarget(BaseModel):
    """Embedded reference info so the admin UI can show what was bought."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    purpose: OrderPurpose
    course_id: uuid.UUID | None
    audiobook_id: uuid.UUID | None
    amount: Decimal
    currency: str
    payment_method: OrderPaymentMethod
    status: OrderStatus
    payment_proof_url: str | None
    admin_note: str | None
    reviewed_at: datetime | None
    reviewed_by: uuid.UUID | None
    created_at: datetime
    target_title: str | None = None


class OrderAdminListItem(BaseModel):
    """Includes a hydrated title for the target and contact info for the user."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    user_full_name: str | None = None
    user_phone: str | None = None
    purpose: OrderPurpose
    course_id: uuid.UUID | None
    audiobook_id: uuid.UUID | None
    target_title: str | None = None
    amount: Decimal
    currency: str
    payment_method: OrderPaymentMethod
    status: OrderStatus
    payment_proof_url: str | None
    admin_note: str | None
    reviewed_at: datetime | None
    created_at: datetime


class OrderAdminAction(BaseModel):
    admin_note: str | None = None
