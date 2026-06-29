"""add certificate_requests table

Revision ID: f4a5b6c7d8e9
Revises: d2e3f4a5b6c7
Create Date: 2026-06-27 12:00:00.000000
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "f4a5b6c7d8e9"
down_revision = "d2e3f4a5b6c7"
branch_labels = None
depends_on = None

certificate_request_status = postgresql.ENUM(
    "pending", "approved", "rejected",
    name="certificate_request_status",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()
    certificate_request_status.create(bind, checkfirst=True)

    op.create_table(
        "certificate_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "course_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("courses.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("full_name", sa.String(200), nullable=False),
        sa.Column(
            "status",
            certificate_request_status,
            nullable=False,
            server_default="pending",
            index=True,
        ),
        sa.Column("rejection_reason", sa.Text, nullable=True),
        sa.Column(
            "reviewed_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("certificate_requests")
    bind = op.get_bind()
    certificate_request_status.drop(bind, checkfirst=True)
