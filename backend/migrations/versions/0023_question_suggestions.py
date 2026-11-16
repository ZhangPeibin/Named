"""add question follow-up suggestions

Revision ID: 0023_question_suggestions
Revises: 0022_question_message_sequence
Create Date: 2026-11-16 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0023_question_suggestions"
down_revision: str | Sequence[str] | None = "0022_question_message_sequence"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "question_messages",
        sa.Column("suggestions_json", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("question_messages", "suggestions_json")
