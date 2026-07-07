"""add city audience option to push notifications

Revision ID: l3m4n5o6p7q8
Revises: k2l3m4n5o6p7
Create Date: 2026-07-07
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision = "l3m4n5o6p7q8"
down_revision: Union[str, None] = "k2l3m4n5o6p7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TYPE push_audience ADD VALUE IF NOT EXISTS 'city'")
    op.add_column(
        "push_notifications", sa.Column("target_city", sa.String(length=120), nullable=True)
    )


def downgrade() -> None:
    # Postgres can't drop a single enum value in place; leaving 'city' in the
    # type on downgrade is harmless since nothing will write it anymore.
    op.drop_column("push_notifications", "target_city")
