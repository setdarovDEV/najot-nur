"""Security session model — tracks every authenticated login and the
real-time state of the protected Flutter client.

A row is created when the user authenticates (mobile or web) and updated on a
heartbeat. The mobile client also reports security events through here
(screen-capture attempts, jailbreak signals, etc.) and uploads short audio
clips captured at login for identity verification.
"""
from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class SecurityEventType(str, enum.Enum):
    """Discrete security-relevant events reported by the mobile client."""

    session_started = "session_started"
    session_heartbeat = "session_heartbeat"
    session_ended = "session_ended"
    screen_capture_attempt = "screen_capture_attempt"
    screenshot_attempt = "screenshot_attempt"
    screen_recording_detected = "screen_recording_detected"
    root_or_jailbreak = "root_or_jailbreak"
    dev_mode_enabled = "dev_mode_enabled"
    vpn_or_proxy = "vpn_or_proxy"
    unusual_location = "unusual_location"
    multiple_active_sessions = "multiple_active_sessions"
    permission_denied_camera = "permission_denied_camera"
    permission_denied_microphone = "permission_denied_microphone"
    auto_recording_uploaded = "auto_recording_uploaded"


class SecuritySession(UUIDMixin, TimestampMixin, Base):
    """One row per authenticated client session."""

    __tablename__ = "security_sessions"
    __table_args__ = (
        Index("ix_security_sessions_user_active", "user_id", "is_active"),
        Index("ix_security_sessions_token_jti", "token_jti"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # JWT id (jti) of the access token that opened this session — used to
    # invalidate the session when the user signs out or is locked.
    token_jti: Mapped[str | None] = mapped_column(String(64), nullable=True)

    # Lifecycle
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    last_heartbeat_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    ended_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Client fingerprint
    platform: Mapped[str] = mapped_column(String(16), nullable=False)
    os_version: Mapped[str | None] = mapped_column(String(64))
    app_version: Mapped[str | None] = mapped_column(String(32))
    device_model: Mapped[str | None] = mapped_column(String(128))
    device_id: Mapped[str | None] = mapped_column(String(128), index=True)
    locale: Mapped[str | None] = mapped_column(String(8))

    # Network
    ip_address: Mapped[str | None] = mapped_column(String(64))
    user_agent: Mapped[str | None] = mapped_column(String(512))

    # Geo (optional, derived from IP server-side)
    country: Mapped[str | None] = mapped_column(String(4))
    city: Mapped[str | None] = mapped_column(String(128))

    # Watermark text shown across the app for this session
    watermark_text: Mapped[str | None] = mapped_column(String(160))

    # Counters
    screen_capture_attempts: Mapped[int] = mapped_column(
        BigInteger, default=0, nullable=False
    )
    screenshot_attempts: Mapped[int] = mapped_column(
        BigInteger, default=0, nullable=False
    )
    auto_recordings_uploaded: Mapped[int] = mapped_column(
        BigInteger, default=0, nullable=False
    )

    events: Mapped[list["SecuritySessionEvent"]] = relationship(
        back_populates="session",
        cascade="all, delete-orphan",
    )


class SecuritySessionEvent(UUIDMixin, TimestampMixin, Base):
    """Append-only audit log of security events for a session."""

    __tablename__ = "security_session_events"
    __table_args__ = (
        Index("ix_security_events_session_type", "session_id", "type"),
    )

    session_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("security_sessions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    type: Mapped[SecurityEventType] = mapped_column(
        Enum(SecurityEventType, name="security_event_type"), nullable=False
    )
    # Free-form metadata — screen capture OS version, exact GPS, etc.
    payload: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    note: Mapped[str | None] = mapped_column(Text)

    session: Mapped["SecuritySession"] = relationship(back_populates="events")
