"""update order_payment_method enum: click/payme → uzum/uzum_nasiya

Revision ID: h8i9j0k1l2m3
Revises: g7h8i9j0k1l2
Create Date: 2026-06-30
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision = "h8i9j0k1l2m3"
down_revision: str | None = "g7h8i9j0k1l2"
branch_labels = None
depends_on = None


OLD_VALUES = ("click", "payme")
NEW_VALUES = ("uzum", "uzum_nasiya", "cash")
TYPE_NAME = "order_payment_method"


def upgrade() -> None:
    bind = op.get_bind()

    # 1. Rename old enum to free up the name.
    op.execute(f'ALTER TYPE "{TYPE_NAME}" RENAME TO "{TYPE_NAME}_old"')

    # 2. Create the new enum with the desired values.
    new_enum = sa.Enum(*NEW_VALUES, name=TYPE_NAME)
    new_enum.create(bind, checkfirst=True)

    # 3. Convert the column to the new enum, defaulting legacy rows to 'cash'
    #    (safest fallback — admin can re-classify in the panel if needed).
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
                WHEN "payment_method"::text IN ('{NEW_VALUES[0]}', '{NEW_VALUES[1]}', '{NEW_VALUES[2]}')
                    THEN "payment_method"::text::{TYPE_NAME}
                ELSE 'cash'
            END
        )
        """
    )
    op.execute(
        f"""
        ALTER TABLE "orders"
        ALTER COLUMN "payment_method" SET DEFAULT 'cash'
        """
    )

    # 4. Drop the old enum.
    op.execute(f'DROP TYPE "{TYPE_NAME}_old"')


def downgrade() -> None:
    bind = op.get_bind()

    op.execute(f'ALTER TYPE "{TYPE_NAME}" RENAME TO "{TYPE_NAME}_new"')
    old_enum = sa.Enum(*OLD_VALUES, "cash", name=TYPE_NAME)
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
                WHEN "payment_method"::text IN ('click', 'payme')
                    THEN "payment_method"::text::{TYPE_NAME}
                ELSE 'cash'
            END
        )
        """
    )
    op.execute(
        f"""
        ALTER TABLE "orders"
        ALTER COLUMN "payment_method" SET DEFAULT 'cash'
        """
    )

    op.execute(f'DROP TYPE "{TYPE_NAME}_new"')
