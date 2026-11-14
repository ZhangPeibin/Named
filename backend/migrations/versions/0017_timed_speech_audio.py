"""add timed speech audio

Revision ID: 0017_timed_speech_audio
Revises: 0016_daily_readings
Create Date: 2026-11-13 00:30:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0017_timed_speech_audio"
down_revision: str | Sequence[str] | None = "0016_daily_readings"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "timed_speech_audio",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("cache_key", sa.String(length=64), nullable=False),
        sa.Column("object_key", sa.String(length=255), nullable=False),
        sa.Column("format", sa.String(length=16), nullable=False),
        sa.Column("words_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_timed_speech_audio_cache_key"),
        "timed_speech_audio",
        ["cache_key"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_timed_speech_audio_cache_key"),
        table_name="timed_speech_audio",
    )
    op.drop_table("timed_speech_audio")
