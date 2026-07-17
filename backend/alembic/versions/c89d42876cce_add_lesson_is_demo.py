"""add lesson is_demo

Revision ID: c89d42876cce
Revises: n5o6p7q8r9s0
Create Date: 2026-07-17 00:00:00.000000
"""
from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "c89d42876cce"
down_revision: str | None = "n5o6p7q8r9s0"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "lessons",
        sa.Column(
            "is_demo",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.create_index("ix_lessons_is_demo", "lessons", ["is_demo"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_lessons_is_demo", table_name="lessons")
    op.drop_column("lessons", "is_demo")
