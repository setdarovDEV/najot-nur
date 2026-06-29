"""Audiobooks, their (editable) pages, per-user listening progress and
per-user access grants (granted when an admin approves a paid zayavka)."""
from __future__ import annotations

import uuid

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class Audiobook(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "audiobooks"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    author: Mapped[str | None] = mapped_column(String(160))
    slug: Mapped[str] = mapped_column(String(220), unique=True, index=True)
    cover_url: Mapped[str | None] = mapped_column(String(512))
    description: Mapped[str | None] = mapped_column(Text)
    category: Mapped[str | None] = mapped_column(String(80))
    is_free: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    price: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    total_pages: Mapped[int] = mapped_column(Integer, default=0)
    is_published: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    audio_url: Mapped[str | None] = mapped_column(String(512))

    pages: Mapped[list["AudiobookPage"]] = relationship(
        back_populates="audiobook",
        cascade="all, delete-orphan",
        order_by="AudiobookPage.page_number",
    )


class AudiobookPage(UUIDMixin, TimestampMixin, Base):
    """An editable page of text + optional narration audio."""

    __tablename__ = "audiobook_pages"
    __table_args__ = (
        UniqueConstraint("audiobook_id", "page_number", name="audiobook_page"),
    )

    audiobook_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("audiobooks.id", ondelete="CASCADE"), index=True
    )
    page_number: Mapped[int] = mapped_column(Integer, nullable=False)
    content: Mapped[str | None] = mapped_column(Text)
    audio_url: Mapped[str | None] = mapped_column(String(512))

    audiobook: Mapped["Audiobook"] = relationship(back_populates="pages")


class AudiobookProgress(UUIDMixin, Base):
    __tablename__ = "audiobook_progress"
    __table_args__ = (
        UniqueConstraint("user_id", "audiobook_id", name="user_audiobook"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    audiobook_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("audiobooks.id", ondelete="CASCADE"), index=True
    )
    current_page: Mapped[int] = mapped_column(Integer, default=1)
    last_listened_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class AudiobookAccess(UUIDMixin, Base):
    """A user-level grant to read a (paid) audiobook.

    Free audiobooks don't need an access row — anyone can read them.
    A row is created when an admin approves a paid zayavka for the
    corresponding audiobook.
    """

    __tablename__ = "audiobook_access"
    __table_args__ = (
        UniqueConstraint("user_id", "audiobook_id", name="user_audiobook_access"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    audiobook_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("audiobooks.id", ondelete="CASCADE"), index=True
    )
    granted_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
