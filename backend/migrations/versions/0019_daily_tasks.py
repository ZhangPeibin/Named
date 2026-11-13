"""add daily task completion fields

Revision ID: 0019_daily_tasks
Revises: 0018_daily_translations
Create Date: 2026-11-13 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0019_daily_tasks"
down_revision: str | Sequence[str] | None = "0018_daily_translations"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("daily_readings", sa.Column("theme", sa.String(length=64), nullable=True))
    op.add_column("daily_readings", sa.Column("completed_at", sa.DateTime(), nullable=True))
    op.add_column(
        "daily_readings",
        sa.Column("completed_duration_seconds", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("daily_readings", "completed_duration_seconds")
    op.drop_column("daily_readings", "completed_at")
    op.drop_column("daily_readings", "theme")
