"""add practice tracking

Revision ID: 0026_practice_tracking
Revises: 0025_drop_word_review
Create Date: 2026-11-22 10:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0026_practice_tracking"
down_revision: str | Sequence[str] | None = "0025_drop_word_review"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "word_progress",
        sa.Column("practice_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column("word_progress", sa.Column("last_practiced_at", sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column("word_progress", "last_practiced_at")
    op.drop_column("word_progress", "practice_count")
