"""drop word review tracking

Revision ID: 0025_drop_word_review
Revises: 5ac3cb55210d
Create Date: 2026-11-21 16:10:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0025_drop_word_review"
down_revision: str | Sequence[str] | None = "5ac3cb55210d"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.drop_column("word_progress", "last_reviewed_at")
    op.drop_column("word_progress", "review_count")


def downgrade() -> None:
    op.add_column(
        "word_progress", sa.Column("review_count", sa.Integer(), nullable=False, server_default="0")
    )
    op.add_column("word_progress", sa.Column("last_reviewed_at", sa.DateTime(), nullable=True))
