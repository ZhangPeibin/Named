"""add challenge theme

Revision ID: 5ac3cb55210d
Revises: 0024_question_feedback
Create Date: 2026-11-20 10:36:22.736051
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "5ac3cb55210d"
down_revision: str | Sequence[str] | None = "2599e6d4bc1c"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("challenges", sa.Column("theme", sa.String(length=120), nullable=True))


def downgrade() -> None:
    op.drop_column("challenges", "theme")
