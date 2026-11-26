"""add word content level

Revision ID: 0030_word_content_level
Revises: 0029_drop_soul_items
Create Date: 2026-11-25 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0030_word_content_level"
down_revision: str | Sequence[str] | None = "0029_drop_soul_items"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "word_contents",
        sa.Column(
            "content_level",
            sa.String(length=8),
            nullable=False,
            server_default="full",
        ),
    )
    op.create_index(
        "ix_word_contents_level_lookup",
        "word_contents",
        ["word_id", "native_language", "content_level", "created_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_word_contents_level_lookup", table_name="word_contents")
    op.drop_column("word_contents", "content_level")
