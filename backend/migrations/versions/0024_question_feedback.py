"""add question answer feedback

Revision ID: 0024_question_feedback
Revises: 0023_question_suggestions
Create Date: 2026-11-16 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0024_question_feedback"
down_revision: str | Sequence[str] | None = "0023_question_suggestions"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "question_messages",
        sa.Column("feedback", sa.String(length=16), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("question_messages", "feedback")
