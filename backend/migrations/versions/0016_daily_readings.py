"""add daily readings

Revision ID: 0016_daily_readings
Revises: 0015_challenges
Create Date: 2026-11-13 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0016_daily_readings"
down_revision: str | Sequence[str] | None = "0015_challenges"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "daily_readings",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("reading_date", sa.Date(), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("passage", sa.Text(), nullable=False),
        sa.Column("target_words_json", sa.JSON(), nullable=False),
        sa.Column("question", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "account_id",
            "reading_date",
            name="uq_daily_readings_account_date",
        ),
    )
    op.create_index(
        op.f("ix_daily_readings_account_id"),
        "daily_readings",
        ["account_id"],
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_daily_readings_account_id"), table_name="daily_readings")
    op.drop_table("daily_readings")
