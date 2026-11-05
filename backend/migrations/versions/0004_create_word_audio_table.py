"""create word audio table

Revision ID: 0004_word_audio
Revises: 0003_discovery
Create Date: 2026-11-04
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004_word_audio"
down_revision: str | None = "0003_discovery"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "word_audio",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("word_id", sa.String(length=36), nullable=False),
        sa.Column("region", sa.String(length=8), nullable=False),
        sa.Column("voice_id", sa.String(length=64), nullable=False),
        sa.Column("format", sa.String(length=16), nullable=False),
        sa.Column("rate", sa.Float(), nullable=False),
        sa.Column("cache_key", sa.String(length=64), nullable=False),
        sa.Column("object_key", sa.String(length=255), nullable=False),
        sa.Column("source", sa.String(length=16), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["word_id"], ["words.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_word_audio_word_id", "word_audio", ["word_id"], unique=False)
    op.create_index("ix_word_audio_cache_key", "word_audio", ["cache_key"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_word_audio_cache_key", table_name="word_audio")
    op.drop_index("ix_word_audio_word_id", table_name="word_audio")
    op.drop_table("word_audio")
