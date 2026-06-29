"""add support_messages table

Revision ID: c9d3e2f1a0b7
Revises: a3f2c1d4e5b6
Create Date: 2026-06-22 10:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'c9d3e2f1a0b7'
down_revision: Union[str, None] = 'a3f2c1d4e5b6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'support_messages',
        sa.Column('text', sa.Text(), nullable=False),
        sa.Column('is_from_user', sa.Boolean(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('sent_by', sa.Uuid(), nullable=True),
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
            ['sent_by'],
            ['users.id'],
            name=op.f('fk_support_messages_sent_by_users'),
            ondelete='SET NULL',
        ),
        sa.ForeignKeyConstraint(
            ['user_id'],
            ['users.id'],
            name=op.f('fk_support_messages_user_id_users'),
            ondelete='CASCADE',
        ),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_support_messages')),
    )
    op.create_index(
        op.f('ix_support_messages_user_id'),
        'support_messages',
        ['user_id'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f('ix_support_messages_user_id'), table_name='support_messages'
    )
    op.drop_table('support_messages')
