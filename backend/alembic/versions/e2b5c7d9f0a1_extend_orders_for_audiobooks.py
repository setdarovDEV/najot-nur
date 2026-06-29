"""extend orders for audiobooks + add audiobook_access

Revision ID: e2b5c7d9f0a1
Revises: d1e4f3a2b8c9
Create Date: 2026-06-23 10:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "e2b5c7d9f0a1"
down_revision: Union[str, None] = "d1e4f3a2b8c9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


order_purpose = postgresql.ENUM(
    "course", "audiobook", name="order_purpose", create_type=True
)


def upgrade() -> None:
    # ── Orders: make course_id nullable, add audiobook_id + purpose ──
    op.alter_column("orders", "course_id", existing_type=sa.Uuid(), nullable=True)

    order_purpose.create(op.get_bind(), checkfirst=True)
    op.add_column(
        "orders",
        sa.Column(
            "purpose",
            postgresql.ENUM(
                "course", "audiobook", name="order_purpose", create_type=False
            ),
            nullable=False,
            server_default="course",
        ),
    )
    op.add_column(
        "orders",
        sa.Column(
            "audiobook_id",
            sa.Uuid(),
            sa.ForeignKey("audiobooks.id", ondelete="CASCADE"),
            nullable=True,
        ),
    )
    op.create_index("ix_orders_audiobook_id", "orders", ["audiobook_id"])
    op.create_index("ix_orders_purpose", "orders", ["purpose"])

    # ── New: audiobook_access ──
    op.create_table(
        "audiobook_access",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("audiobook_id", sa.Uuid(), nullable=False),
        sa.Column(
            "granted_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["audiobook_id"],
            ["audiobooks.id"],
            ondelete="CASCADE",
            name="fk_audiobook_access_audiobook_id_audiobooks",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
            name="fk_audiobook_access_user_id_users",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_audiobook_access"),
        sa.UniqueConstraint("user_id", "audiobook_id", name="user_audiobook_access"),
    )
    op.create_index(
        "ix_audiobook_access_user_id", "audiobook_access", ["user_id"]
    )
    op.create_index(
        "ix_audiobook_access_audiobook_id", "audiobook_access", ["audiobook_id"]
    )


def downgrade() -> None:
    op.drop_index("ix_audiobook_access_audiobook_id", "audiobook_access")
    op.drop_index("ix_audiobook_access_user_id", "audiobook_access")
    op.drop_table("audiobook_access")

    op.drop_index("ix_orders_purpose", "orders")
    op.drop_index("ix_orders_audiobook_id", "orders")
    op.drop_column("orders", "audiobook_id")
    op.drop_column("orders", "purpose")
    op.alter_column("orders", "course_id", existing_type=sa.Uuid(), nullable=False)

    order_purpose.drop(op.get_bind(), checkfirst=True)
