"""create discovery and word tables

Revision ID: 0003_discovery
Revises: 0002_soul
Create Date: 2026-11-04
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003_discovery"
down_revision: str | None = "0002_soul"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "words",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("canonical_key", sa.String(length=200), nullable=False),
        sa.Column("label_en", sa.String(length=200), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_words_canonical_key", "words", ["canonical_key"], unique=True)

    op.create_table(
        "word_contents",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("word_id", sa.String(length=36), nullable=False),
        sa.Column("native_language", sa.String(length=32), nullable=False),
        sa.Column("payload_json", sa.JSON(), nullable=False),
        sa.Column("source", sa.String(length=16), nullable=False),
        sa.Column("model", sa.String(length=120), nullable=False),
        sa.Column("prompt_version", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["word_id"], ["words.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_word_contents_word_id", "word_contents", ["word_id"], unique=False)

    op.create_table(
        "discoveries",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("input_type", sa.String(length=16), nullable=False),
        sa.Column("input_text", sa.Text(), nullable=True),
        sa.Column("context", sa.Text(), nullable=True),
        sa.Column("image_key", sa.String(length=255), nullable=True),
        sa.Column("input_language", sa.String(length=16), nullable=True),
        sa.Column("focus_kind", sa.String(length=16), nullable=True),
        sa.Column("word_id", sa.String(length=36), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("warnings_json", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["word_id"], ["words.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_discoveries_account_id", "discoveries", ["account_id"], unique=False)

    op.create_table(
        "discovery_candidates",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("discovery_id", sa.String(length=36), nullable=False),
        sa.Column("label_en", sa.String(length=200), nullable=False),
        sa.Column("label_zh", sa.String(length=200), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("selected", sa.Boolean(), server_default=sa.false(), nullable=False),
        sa.Column("provider", sa.String(length=32), nullable=False),
        sa.Column("raw_json", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["discovery_id"], ["discoveries.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_discovery_candidates_discovery_id",
        "discovery_candidates",
        ["discovery_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_discovery_candidates_discovery_id", table_name="discovery_candidates")
    op.drop_table("discovery_candidates")
    op.drop_index("ix_discoveries_account_id", table_name="discoveries")
    op.drop_table("discoveries")
    op.drop_index("ix_word_contents_word_id", table_name="word_contents")
    op.drop_table("word_contents")
    op.drop_index("ix_words_canonical_key", table_name="words")
    op.drop_table("words")
