"""add question message sequence

Revision ID: 0022_question_message_sequence
Revises: 0021_question_threads
Create Date: 2026-11-16 00:00:00.000000
"""

from collections import defaultdict
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0022_question_message_sequence"
down_revision: str | Sequence[str] | None = "0021_question_threads"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "question_messages",
        sa.Column("sequence", sa.Integer(), nullable=False, server_default="0"),
    )
    bind = op.get_bind()
    rows = list(
        bind.execute(
            sa.text(
                "SELECT id, thread_id FROM question_messages ORDER BY thread_id, created_at, id"
            )
        ).mappings()
    )
    next_by_thread = defaultdict(int)
    for row in rows:
        next_by_thread[row["thread_id"]] += 1
        bind.execute(
            sa.text("UPDATE question_messages SET sequence = :sequence WHERE id = :id"),
            {
                "sequence": next_by_thread[row["thread_id"]],
                "id": row["id"],
            },
        )


def downgrade() -> None:
    op.drop_column("question_messages", "sequence")
