"""add audiobook audio_url

Revision ID: a3f2c1d4e5b6
Revises: 14e7271fac68
Create Date: 2026-06-22 06:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = 'a3f2c1d4e5b6'
down_revision: Union[str, None] = '14e7271fac68'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('audiobooks', sa.Column('audio_url', sa.String(512), nullable=True))


def downgrade() -> None:
    op.drop_column('audiobooks', 'audio_url')
