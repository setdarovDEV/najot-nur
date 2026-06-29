"""add deep char-level analysis columns to voice_analyses (TZ §3.5)

Revision ID: b7c8d9e0f1a2
Revises: f3a1b2c4d5e6
Create Date: 2026-06-26 11:00:00.000000
"""
from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

from alembic import op

revision: str = "b7c8d9e0f1a2"
down_revision: str | None = "f3a1b2c4d5e6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("voice_analyses", sa.Column("word_analysis", JSONB, nullable=True))
    op.add_column("voice_analyses", sa.Column("char_stats", JSONB, nullable=True))


def downgrade() -> None:
    op.drop_column("voice_analyses", "char_stats")
    op.drop_column("voice_analyses", "word_analysis")
