"""add security_sessions + security_session_events

Revision ID: g7h8i9j0k1l2
Revises: a1b2c3d4e5f6, e5f6g7h8i9j0
Create Date: 2026-06-29
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "g7h8i9j0k1l2"
down_revision = ("a1b2c3d4e5f6", "e5f6g7h8i9j0")
branch_labels = None
depends_on = None


def upgrade() -> None:
    security_event_type = sa.Enum(
        "session_started",
        "session_heartbeat",
        "session_ended",
        "screen_capture_attempt",
        "screenshot_attempt",
        "screen_recording_detected",
        "root_or_jailbreak",
        "dev_mode_enabled",
        "vpn_or_proxy",
        "unusual_location",
        "multiple_active_sessions",
        "permission_denied_camera",
        "permission_denied_microphone",
        "auto_recording_uploaded",
        name="security_event_type",
    )
    security_event_type.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "security_sessions",
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("token_jti", sa.String(length=64), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("last_heartbeat_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("platform", sa.String(length=16), nullable=False),
        sa.Column("os_version", sa.String(length=64), nullable=True),
        sa.Column("app_version", sa.String(length=32), nullable=True),
        sa.Column("device_model", sa.String(length=128), nullable=True),
        sa.Column("device_id", sa.String(length=128), nullable=True),
        sa.Column("locale", sa.String(length=8), nullable=True),
        sa.Column("ip_address", sa.String(length=64), nullable=True),
        sa.Column("user_agent", sa.String(length=512), nullable=True),
        sa.Column("country", sa.String(length=4), nullable=True),
        sa.Column("city", sa.String(length=128), nullable=True),
        sa.Column("watermark_text", sa.String(length=160), nullable=True),
        sa.Column("screen_capture_attempts", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("screenshot_attempts", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("auto_recordings_uploaded", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_security_sessions")),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE", name=op.f("fk_security_sessions_user_id_users")),
    )
    op.create_index("ix_security_sessions_user_id", "security_sessions", ["user_id"])
    op.create_index("ix_security_sessions_device_id", "security_sessions", ["device_id"])
    op.create_index("ix_security_sessions_token_jti", "security_sessions", ["token_jti"])
    op.create_index("ix_security_sessions_user_active", "security_sessions", ["user_id", "is_active"])

    op.create_table(
        "security_session_events",
        sa.Column("session_id", sa.UUID(), nullable=False),
        sa.Column(
            "type",
            security_event_type,
            nullable=False,
        ),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_security_session_events")),
        sa.ForeignKeyConstraint(["session_id"], ["security_sessions.id"], ondelete="CASCADE", name=op.f("fk_security_session_events_session_id_security_sessions")),
    )
    op.create_index("ix_security_session_events_session_id", "security_session_events", ["session_id"])
    op.create_index("ix_security_events_session_type", "security_session_events", ["session_id", "type"])


def downgrade() -> None:
    op.drop_index("ix_security_events_session_type", table_name="security_session_events")
    op.drop_index("ix_security_session_events_session_id", table_name="security_session_events")
    op.drop_table("security_session_events")
    op.drop_index("ix_security_sessions_user_active", table_name="security_sessions")
    op.drop_index("ix_security_sessions_token_jti", table_name="security_sessions")
    op.drop_index("ix_security_sessions_device_id", table_name="security_sessions")
    op.drop_index("ix_security_sessions_user_id", table_name="security_sessions")
    op.drop_table("security_sessions")
    sa.Enum(name="security_event_type").drop(op.get_bind(), checkfirst=True)
