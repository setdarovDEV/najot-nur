"""Payment records (Uzum / Uzum Nasiya / ATMOS). Integration is a later phase;
the model is in place so the schema and admin reporting are ready."""
from __future__ import annotations

import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import PaymentProvider, PaymentPurpose, PaymentStatus


class Payment(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "payments"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    provider: Mapped[PaymentProvider] = mapped_column(
        Enum(PaymentProvider, name="payment_provider")
    )
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status"),
        default=PaymentStatus.pending,
        index=True,
    )
    purpose: Mapped[PaymentPurpose] = mapped_column(
        Enum(PaymentPurpose, name="payment_purpose")
    )
    # id of the course / audiobook / subscription plan being paid for
    reference_id: Mapped[uuid.UUID | None] = mapped_column()
    external_id: Mapped[str | None] = mapped_column(String(255), index=True)
    paid_at: Mapped[object | None] = mapped_column(DateTime(timezone=True))
