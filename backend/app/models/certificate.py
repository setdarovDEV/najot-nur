"""Course-completion certificates (PDF)."""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class Certificate(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "certificates"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    course_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("courses.id", ondelete="CASCADE"), index=True
    )
    serial_number: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    pdf_url: Mapped[str | None] = mapped_column(String(512))
    grade: Mapped[int | None] = mapped_column(Integer)  # final score 0-100
