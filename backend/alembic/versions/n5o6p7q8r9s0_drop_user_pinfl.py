"""drop pinfl from users (PINFL workaround abandoned — didn't fix Uzum's crash)

Revision ID: n5o6p7q8r9s0
Revises: m4n5o6p7q8r9
Create Date: 2026-07-15
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision = "n5o6p7q8r9s0"
down_revision: Union[str, None] = "m4n5o6p7q8r9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_column("users", "pinfl")


def downgrade() -> None:
    op.add_column("users", sa.Column("pinfl", sa.String(length=14), nullable=True))
