"""add annotation learning fields

Revision ID: 0010_annotation_learning
Revises: 0009_memory_items
Create Date: 2026-11-10 10:40:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0010_annotation_learning"
down_revision: str | Sequence[str] | None = "0009_memory_items"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "message_annotations",
        sa.Column("part_of_speech", sa.String(length=32), nullable=True),
    )
    op.add_column(
        "message_annotations",
        sa.Column("grammar", sa.String(length=500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("message_annotations", "grammar")
    op.drop_column("message_annotations", "part_of_speech")
