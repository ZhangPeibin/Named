"""add question exchanges

Revision ID: 0020_questions
Revises: 0019_daily_tasks
Create Date: 2026-11-16 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0020_questions"
down_revision: str | Sequence[str] | None = "0019_daily_tasks"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "question_exchanges",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("question", sa.Text(), nullable=False),
        sa.Column("answer", sa.Text(), nullable=False),
        sa.Column("native_explanation", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_question_exchanges_account_id"),
        "question_exchanges",
        ["account_id"],
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_question_exchanges_account_id"), table_name="question_exchanges")
    op.drop_table("question_exchanges")
