"""add daily translations

Revision ID: 0018_daily_translations
Revises: 0017_timed_speech_audio
Create Date: 2026-11-13 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0018_daily_translations"
down_revision: str | Sequence[str] | None = "0017_timed_speech_audio"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("daily_readings", sa.Column("translation_json", sa.JSON(), nullable=True))
    op.add_column(
        "daily_readings",
        sa.Column("translation_language", sa.String(length=32), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("daily_readings", "translation_language")
    op.drop_column("daily_readings", "translation_json")
