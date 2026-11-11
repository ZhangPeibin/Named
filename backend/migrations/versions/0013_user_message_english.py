"""add English rendering for non-English user messages

Revision ID: 0013_user_message_english
Revises: 0012_error_patterns
Create Date: 2026-11-10 17:30:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0013_user_message_english"
down_revision: str | Sequence[str] | None = "0012_error_patterns"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "conversation_messages",
        sa.Column("english_text", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("conversation_messages", "english_text")
