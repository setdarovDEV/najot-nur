"""Order model — manual payment approval for courses and audiobooks.

User submits a *zayavka* via the mobile app (chooses a payment method and
optionally pastes a receipt URL). An admin reviews it in the panel and
either approves (which grants access) or rejects.
"""
from __future__ import annotations

import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import OrderPaymentMethod, OrderPurpose, OrderStatus


class Order(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "orders"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    purpose: Mapped[OrderPurpose] = mapped_column(
        Enum(OrderPurpose, name="order_purpose"),
        default=OrderPurpose.course,
        index=True,
    )
    course_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"), index=True
    )
    audiobook_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("audiobooks.id", ondelete="CASCADE"), index=True
    )
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="UZS")
    payment_method: Mapped[OrderPaymentMethod] = mapped_column(
        Enum(OrderPaymentMethod, name="order_payment_method")
    )
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, name="order_status"),
        default=OrderStatus.pending,
        index=True,
    )
    payment_proof_url: Mapped[str | None] = mapped_column(String(512))
    admin_note: Mapped[str | None] = mapped_column(Text)
    reviewed_at: Mapped[object | None] = mapped_column(DateTime(timezone=True))
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
