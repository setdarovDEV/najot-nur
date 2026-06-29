"""Certificate request submitted by a user, reviewed by a curator."""
from __future__ import annotations

import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import CertificateRequestStatus


class CertificateRequest(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "certificate_requests"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    course_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"), index=True
    )
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    status: Mapped[CertificateRequestStatus] = mapped_column(
        Enum(CertificateRequestStatus, name="certificate_request_status"),
        default=CertificateRequestStatus.pending,
        index=True,
    )
    rejection_reason: Mapped[str | None] = mapped_column(Text)
    reviewed_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    reviewed_at: Mapped[object | None] = mapped_column(DateTime(timezone=True))
