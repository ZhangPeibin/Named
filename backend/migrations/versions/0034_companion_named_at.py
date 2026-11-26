"""add companion named_at

Revision ID: 0034_companion_named_at
Revises: 0033_about_identity_memories
Create Date: 2026-11-26 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0034_companion_named_at"
down_revision: str | Sequence[str] | None = "0033_about_identity_memories"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "companion_profiles",
        sa.Column("named_at", sa.DateTime(), nullable=True),
    )
    op.execute(
        "UPDATE companion_profiles SET named_at = CURRENT_TIMESTAMP "
        "WHERE name IS NOT NULL AND named_at IS NULL"
    )


def downgrade() -> None:
    op.drop_column("companion_profiles", "named_at")
