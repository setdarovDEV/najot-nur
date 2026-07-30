"""add lesson hls_url, poster_url, video_status

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-07-30 00:00:00.000000
"""
from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "e5f6a7b8c9d0"
down_revision: str | None = "d4e5f6a7b8c9"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("lessons", sa.Column("hls_url", sa.String(512), nullable=True))
    op.add_column("lessons", sa.Column("poster_url", sa.String(512), nullable=True))
    op.add_column("lessons", sa.Column("video_status", sa.String(20), nullable=True))
    # Videos uploaded before the transcode pipeline existed have no HLS ladder;
    # mark them "ready" so playback keeps falling back to the stored MP4
    # instead of showing a perpetual "processing" state.
    op.execute(
        "UPDATE lessons SET video_status = 'ready' WHERE video_url IS NOT NULL"
    )


def downgrade() -> None:
    op.drop_column("lessons", "video_status")
    op.drop_column("lessons", "poster_url")
    op.drop_column("lessons", "hls_url")
