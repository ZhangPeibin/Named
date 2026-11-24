"""add memory lifecycle fields

Revision ID: 0027_memory_lifecycle
Revises: 0026_practice_tracking
Create Date: 2026-11-23 18:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0027_memory_lifecycle"
down_revision: str | Sequence[str] | None = "0026_practice_tracking"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.drop_constraint(
        "uq_memory_items_account_kind_key",
        "memory_items",
        type_="unique",
    )
    op.add_column(
        "memory_items",
        sa.Column("status", sa.String(length=16), nullable=False, server_default="active"),
    )
    op.add_column("memory_items", sa.Column("superseded_by", sa.String(length=36), nullable=True))
    op.add_column("memory_items", sa.Column("valid_from", sa.DateTime(), nullable=True))
    op.add_column("memory_items", sa.Column("valid_until", sa.DateTime(), nullable=True))
    op.create_index(
        "ix_memory_items_account_kind_key",
        "memory_items",
        ["account_id", "kind", "canonical_key"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_memory_items_superseded_by",
        "memory_items",
        "memory_items",
        ["superseded_by"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_memory_items_superseded_by", "memory_items", type_="foreignkey")
    op.drop_index("ix_memory_items_account_kind_key", table_name="memory_items")
    op.drop_column("memory_items", "valid_until")
    op.drop_column("memory_items", "valid_from")
    op.drop_column("memory_items", "superseded_by")
    op.drop_column("memory_items", "status")
    op.create_unique_constraint(
        "uq_memory_items_account_kind_key",
        "memory_items",
        ["account_id", "kind", "canonical_key"],
    )
