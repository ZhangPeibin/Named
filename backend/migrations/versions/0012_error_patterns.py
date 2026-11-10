"""add error patterns and correction taxonomy

Revision ID: 0012_error_patterns
Revises: 0011_annotation_pronunciation
Create Date: 2026-11-10 14:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0012_error_patterns"
down_revision: str | Sequence[str] | None = "0011_annotation_pronunciation"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "message_corrections",
        sa.Column("category", sa.String(length=32), nullable=True),
    )
    op.add_column(
        "message_corrections",
        sa.Column("pattern", sa.String(length=64), nullable=True),
    )
    op.create_table(
        "error_patterns",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("category", sa.String(length=32), nullable=False),
        sa.Column("pattern_key", sa.String(length=64), nullable=False),
        sa.Column("label", sa.String(length=200), nullable=False),
        sa.Column("occurrence_count", sa.Integer(), nullable=False),
        sa.Column("first_seen_at", sa.DateTime(), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(), nullable=False),
        sa.Column("example_original", sa.Text(), nullable=True),
        sa.Column("example_suggestion", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "account_id",
            "category",
            "pattern_key",
            name="uq_error_patterns_account_category_key",
        ),
    )
    op.create_index(
        op.f("ix_error_patterns_account_id"),
        "error_patterns",
        ["account_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_error_patterns_account_id"), table_name="error_patterns")
    op.drop_table("error_patterns")
    op.drop_column("message_corrections", "pattern")
    op.drop_column("message_corrections", "category")
