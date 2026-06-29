"""Support chat messages — one shared thread per user with admin/curator."""
from __future__ import annotations

import uuid

from sqlalchemy import Boolean, DateTime, ForeignKey, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class SupportMessage(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "support_messages"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    text: Mapped[str] = mapped_column(Text, nullable=False)
    is_from_user: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    sent_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    user: Mapped["User"] = relationship(  # noqa: F821
        foreign_keys=[user_id], lazy="select"
    )
    sender: Mapped["User | None"] = relationship(  # noqa: F821
        foreign_keys=[sent_by], lazy="select"
    )


class SupportThreadRead(UUIDMixin, Base):
    """Per-thread read cursor: tracks the last message read by each side.

    * ``last_user_read_at`` — last message the user has read (admin sees this
      to know which of their replies are still unread for the user).
    * ``last_admin_read_at`` — last message admins/curators have read
      (drives the red ``1`` badge in the admin chat list).
    """

    __tablename__ = "support_thread_reads"
    __table_args__ = (
        UniqueConstraint("user_id", name="uq_support_thread_reads_user_id"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    last_user_read_at: Mapped["DateTime | None"] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_admin_read_at: Mapped["DateTime | None"] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
