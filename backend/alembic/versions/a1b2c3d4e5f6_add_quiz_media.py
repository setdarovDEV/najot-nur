"""add cover_image_url and video_url to quizzes

Revision ID: a1b2c3d4e5f6
Revises: f4a5b6c7d8e9
Create Date: 2026-06-28 23:00:00.000000
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "a1b2c3d4e5f6"
down_revision = "f4a5b6c7d8e9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "quizzes",
        sa.Column("cover_image_url", sa.String(512), nullable=True),
    )
    op.add_column(
        "quizzes",
        sa.Column("video_url", sa.String(512), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("quizzes", "video_url")
    op.drop_column("quizzes", "cover_image_url")
