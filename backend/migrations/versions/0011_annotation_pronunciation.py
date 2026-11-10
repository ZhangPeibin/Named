"""add annotation pronunciation fields

Revision ID: 0011_annotation_pronunciation
Revises: 0010_annotation_learning
Create Date: 2026-11-10 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0011_annotation_pronunciation"
down_revision: str | Sequence[str] | None = "0010_annotation_learning"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("message_annotations", sa.Column("ipa", sa.String(length=64), nullable=True))
    op.add_column(
        "message_annotations",
        sa.Column("syllables", sa.String(length=200), nullable=True),
    )
    op.add_column("message_annotations", sa.Column("vowels", sa.JSON(), nullable=True))
    op.add_column("message_annotations", sa.Column("consonants", sa.JSON(), nullable=True))
    op.add_column(
        "message_annotations",
        sa.Column("phonics", sa.String(length=500), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("message_annotations", "phonics")
    op.drop_column("message_annotations", "consonants")
    op.drop_column("message_annotations", "vowels")
    op.drop_column("message_annotations", "syllables")
    op.drop_column("message_annotations", "ipa")
