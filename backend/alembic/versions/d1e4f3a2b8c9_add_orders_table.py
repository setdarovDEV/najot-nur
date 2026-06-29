"""add orders table (click/payme/cash zayavka flow)

Revision ID: d1e4f3a2b8c9
Revises: c9d3e2f1a0b7
Create Date: 2026-06-22 12:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = 'd1e4f3a2b8c9'
down_revision: Union[str, None] = 'c9d3e2f1a0b7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

order_payment_method = postgresql.ENUM(
    'click', 'payme', 'cash', name='order_payment_method', create_type=True
)
order_status = postgresql.ENUM(
    'pending', 'approved', 'rejected', name='order_status', create_type=True
)


def upgrade() -> None:
    order_payment_method.create(op.get_bind(), checkfirst=True)
    order_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        'orders',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('course_id', sa.Uuid(), nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('currency', sa.String(3), nullable=False, server_default='UZS'),
        sa.Column(
            'payment_method',
            postgresql.ENUM('click', 'payme', 'cash', name='order_payment_method', create_type=False),
            nullable=False,
        ),
        sa.Column(
            'status',
            postgresql.ENUM('pending', 'approved', 'rejected', name='order_status', create_type=False),
            nullable=False,
            server_default='pending',
        ),
        sa.Column('payment_proof_url', sa.String(512), nullable=True),
        sa.Column('admin_note', sa.Text(), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('reviewed_by', sa.Uuid(), nullable=True),
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
        sa.ForeignKeyConstraint(['course_id'], ['courses.id'], ondelete='CASCADE',
                                name='fk_orders_course_id_courses'),
        sa.ForeignKeyConstraint(['reviewed_by'], ['users.id'], ondelete='SET NULL',
                                name='fk_orders_reviewed_by_users'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE',
                                name='fk_orders_user_id_users'),
        sa.PrimaryKeyConstraint('id', name='pk_orders'),
    )
    op.create_index('ix_orders_user_id', 'orders', ['user_id'])
    op.create_index('ix_orders_course_id', 'orders', ['course_id'])
    op.create_index('ix_orders_status', 'orders', ['status'])


def downgrade() -> None:
    op.drop_index('ix_orders_status', 'orders')
    op.drop_index('ix_orders_course_id', 'orders')
    op.drop_index('ix_orders_user_id', 'orders')
    op.drop_table('orders')
    order_payment_method.drop(op.get_bind(), checkfirst=True)
    order_status.drop(op.get_bind(), checkfirst=True)
