"""merge heads and add 'gift' order_payment_method value

Revision ID: j1k2l3m4n5o6
Revises: b1c2d3e4f5a6, h8i9j0k1l2m3
Create Date: 2026-07-06
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision = "j1k2l3m4n5o6"
down_revision: Union[str, tuple[str, ...], None] = ("b1c2d3e4f5a6", "h8i9j0k1l2m3")
branch_labels = None
depends_on = None

TYPE_NAME = "order_payment_method"


def upgrade() -> None:
    op.execute(f"ALTER TYPE \"{TYPE_NAME}\" ADD VALUE IF NOT EXISTS 'gift'")


def downgrade() -> None:
    # Postgres cannot drop a single enum value; recreate the type without it.
    bind = op.get_bind()

    op.execute(f'ALTER TYPE "{TYPE_NAME}" RENAME TO "{TYPE_NAME}_old"')
    old_enum = sa.Enum("uzum", "uzum_nasiya", "cash", name=TYPE_NAME)
    old_enum.create(bind, checkfirst=True)

    op.execute(
        f"""
        ALTER TABLE "orders"
        ALTER COLUMN "payment_method" DROP DEFAULT
        """
    )
    op.execute(
        f"""
        ALTER TABLE "orders"
        ALTER COLUMN "payment_method" TYPE "{TYPE_NAME}"
        USING (
            CASE
                WHEN "payment_method"::text = 'gift' THEN 'cash'
                ELSE "payment_method"::text
            END::{TYPE_NAME}
        )
        """
    )
    op.execute(
        f"""
        ALTER TABLE "orders"
        ALTER COLUMN "payment_method" SET DEFAULT 'cash'
        """
    )

    op.execute(f'DROP TYPE "{TYPE_NAME}_old"')
