"""merge heads

Revision ID: f3a1b2c4d5e6
Revises: e2b5c7d9f0a1, e2f4a1b3c5d6
Create Date: 2026-06-24 00:00:00.000000

"""
from typing import Sequence, Union

revision: str = 'f3a1b2c4d5e6'
down_revision: Union[str, Sequence[str], None] = ('e2b5c7d9f0a1', 'e2f4a1b3c5d6')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
