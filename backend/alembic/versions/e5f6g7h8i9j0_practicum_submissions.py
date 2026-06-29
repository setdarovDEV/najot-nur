"""practicum submissions table

Revision ID: e5f6g7h8i9j0
Revises: f4a5b6c7d8e9
Create Date: 2026-06-28

"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "e5f6g7h8i9j0"
down_revision = "f4a5b6c7d8e9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "practicum_submissions",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("practicum_id", sa.UUID(), nullable=False),
        sa.Column("audio_url", sa.String(512), nullable=True),
        sa.Column("transcript", sa.Text(), nullable=True),
        sa.Column("voice_analysis_id", sa.UUID(), nullable=True),
        sa.Column("overall_score", sa.Integer(), nullable=True),
        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default="pending",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["practicum_id"], ["practicums.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["voice_analysis_id"], ["voice_analyses.id"], ondelete="SET NULL"
        ),
    )
    op.create_index(
        "ix_practicum_submissions_user_id", "practicum_submissions", ["user_id"]
    )
    op.create_index(
        "ix_practicum_submissions_practicum_id",
        "practicum_submissions",
        ["practicum_id"],
    )
    op.create_index(
        "ix_practicum_submissions_status", "practicum_submissions", ["status"]
    )


def downgrade() -> None:
    op.drop_index("ix_practicum_submissions_status", "practicum_submissions")
    op.drop_index("ix_practicum_submissions_practicum_id", "practicum_submissions")
    op.drop_index("ix_practicum_submissions_user_id", "practicum_submissions")
    op.drop_table("practicum_submissions")
