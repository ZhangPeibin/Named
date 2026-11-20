"""add soul and conversation memory controls

Revision ID: 2599e6d4bc1c
Revises: 448f2885c87d
Create Date: 2026-11-20 14:04:27.727494
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "2599e6d4bc1c"
down_revision: str | Sequence[str] | None = "448f2885c87d"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "conversations",
        sa.Column("use_memory", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "soul_profiles",
        sa.Column("auto_extract", sa.Boolean(), nullable=False, server_default=sa.true()),
    )


def downgrade() -> None:
    op.drop_column("soul_profiles", "auto_extract")
    op.drop_column("conversations", "use_memory")
