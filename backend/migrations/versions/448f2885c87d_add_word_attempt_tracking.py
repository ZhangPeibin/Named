"""add word attempt tracking

Revision ID: 448f2885c87d
Revises: 0024_question_feedback
Create Date: 2026-11-20 13:47:36.527997
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "448f2885c87d"
down_revision: str | Sequence[str] | None = "0024_question_feedback"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "word_attempts",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("word_id", sa.String(length=36), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["word_id"], ["words.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_word_attempts_account_id"), "word_attempts", ["account_id"], unique=False
    )
    op.create_index(op.f("ix_word_attempts_word_id"), "word_attempts", ["word_id"], unique=False)
    op.add_column(
        "word_progress",
        sa.Column("attempt_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column("word_progress", sa.Column("last_attempt_at", sa.DateTime(), nullable=True))
    op.add_column(
        "word_progress",
        sa.Column("used_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column("word_progress", sa.Column("last_used_at", sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_table("word_attempts")
    op.drop_column("word_progress", "last_used_at")
    op.drop_column("word_progress", "used_count")
    op.drop_column("word_progress", "last_attempt_at")
    op.drop_column("word_progress", "attempt_count")
