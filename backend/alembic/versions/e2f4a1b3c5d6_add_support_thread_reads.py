"""add support_thread_reads for per-side read state

Revision ID: e2f4a1b3c5d6
Revises: c9d3e2f1a0b7
Create Date: 2026-06-23 12:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'e2f4a1b3c5d6'
down_revision: Union[str, None] = 'c9d3e2f1a0b7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'support_thread_reads',
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('last_user_read_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_admin_read_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column(
            'created_at',
            sa.DateTime(timezone=True),
            server_default=sa.text('now()'),
            nullable=False,
        ),
        sa.Column(
            'updated_at',
            sa.DateTime(timezone=True),
            server_default=sa.text('now()'),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ['user_id'],
            ['users.id'],
            name=op.f('fk_support_thread_reads_user_id_users'),
            ondelete='CASCADE',
        ),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_support_thread_reads')),
        sa.UniqueConstraint('user_id', name='uq_support_thread_reads_user_id'),
    )
    op.create_index(
        op.f('ix_support_thread_reads_user_id'),
        'support_thread_reads',
        ['user_id'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f('ix_support_thread_reads_user_id'), table_name='support_thread_reads'
    )
    op.drop_table('support_thread_reads')
