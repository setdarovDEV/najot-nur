"""Payment schemas."""
from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import PaymentProvider, PaymentPurpose, PaymentStatus


class PaymentInitiate(BaseModel):
    provider: PaymentProvider
    amount: Decimal = Field(..., gt=0, description="Amount in UZS")
    reference_id: uuid.UUID | None = Field(
        None, description="UUID of the course / audiobook / subscription plan"
    )
    purpose: PaymentPurpose
    return_url: str = Field(..., description="URL to redirect to after payment")


class PaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    currency: str
    provider: PaymentProvider
    status: PaymentStatus
    purpose: PaymentPurpose
    reference_id: uuid.UUID | None
    external_id: str | None
    paid_at: datetime | None
    created_at: datetime


class PaymentListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    currency: str
    provider: PaymentProvider
    status: PaymentStatus
    purpose: PaymentPurpose
    reference_id: uuid.UUID | None
    external_id: str | None
    paid_at: datetime | None
    created_at: datetime


class PaymentInitiateResponse(BaseModel):
    payment_id: uuid.UUID
    redirect_url: str
    status: PaymentStatus
