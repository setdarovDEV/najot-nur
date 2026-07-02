"""add practicum.expert_transcript

Caches the STT transcript of ``expert_audio_url`` so the per-submission
analysis pipeline doesn't have to re-transcribe the same audio file every
time a user submits a recording.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'b1c2d3e4f5a6'
down_revision: Union[str, None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'practicums',
        sa.Column('expert_transcript', sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column('practicums', 'expert_transcript')
