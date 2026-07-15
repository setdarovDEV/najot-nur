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
    period: str | None = Field(
        None,
        description=(
            "Uzum Nasiya only: tariff id picked from /payments/uzum-nasiya/calculate "
            "or /check-status (e.g. '6 Default'). Required when provider=uzum_nasiya."
        ),
    )
    product_name: str | None = Field(
        None, description="Uzum Nasiya only: item name shown in the contract."
    )


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


# ──────────────────────────────────────────────
#  Uzum Nasiya (installment) — extra flow endpoints
# ──────────────────────────────────────────────


class NasiyaCheckStatusRequest(BaseModel):
    phone: str | None = Field(
        None, description="998XXXXXXXXX; defaults to the current user's phone on file"
    )


class NasiyaTariffPeriod(BaseModel):
    period: str
    title_uz: str
    title_ru: str
    available_balance: str
    original_markup: int | None = None
    discount_markup: int | None = None


class NasiyaCheckStatusResponse(BaseModel):
    status: int = Field(..., description="Buyer status code — see Uzum Nasiya docs")
    buyer_id: int | None = None
    has_limit: bool = False
    is_in_black_list: bool = False
    webview: str = Field(
        "", description="Open in a WebView when the buyer still needs to register/verify"
    )
    available_periods: list[NasiyaTariffPeriod] = Field(default_factory=list)
    balance: str = "0.00"


class NasiyaCalculateRequest(BaseModel):
    reference_id: uuid.UUID | None = Field(None, description="Course / audiobook id")
    amount: Decimal = Field(..., gt=0, description="Item price in UZS")


class NasiyaCalculatedTariff(BaseModel):
    tariff: str
    tariff_name: str | None = None
    title_uz: str | None = None
    title_ru: str | None = None
    period_months: int
    total: float
    origin: float
    month: float
    is_available: bool
    status: int


class NasiyaCalculateResponse(BaseModel):
    tariffs: list[NasiyaCalculatedTariff]


class NasiyaPaymentActionRequest(BaseModel):
    payment_id: uuid.UUID
