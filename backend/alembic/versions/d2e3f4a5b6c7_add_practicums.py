"""add practicums table

Revision ID: d2e3f4a5b6c7
Revises: f3a1b2c4d5e6, c1d2e3f4a5b6
Create Date: 2026-06-27 10:00:00.000000
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "d2e3f4a5b6c7"
down_revision = ("f3a1b2c4d5e6", "c1d2e3f4a5b6")
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "practicums",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("category", sa.String(80), nullable=True),
        sa.Column("expert_text", sa.Text, nullable=True),
        sa.Column("expert_audio_url", sa.String(512), nullable=True),
        sa.Column("is_free", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("price", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("status", sa.String(20), nullable=False, server_default="draft", index=True),
        sa.Column(
            "created_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "approved_by_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
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
    op.drop_table("practicums")
