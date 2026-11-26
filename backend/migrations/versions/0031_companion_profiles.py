"""add companion profiles

Revision ID: 0031_companion_profiles
Revises: 0030_word_content_level
Create Date: 2026-11-25 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0031_companion_profiles"
down_revision: str | Sequence[str] | None = "0030_word_content_level"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "companion_profiles",
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=64), nullable=True),
        sa.Column("gender", sa.String(length=32), nullable=True),
        sa.Column("hobby", sa.String(length=255), nullable=True),
        sa.Column(
            "avatar_key",
            sa.String(length=64),
            nullable=False,
            server_default="companion_chill",
        ),
        sa.Column(
            "voice_key",
            sa.String(length=64),
            nullable=False,
            server_default="companion_default",
        ),
        sa.Column("setup_dismissed_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("account_id"),
    )


def downgrade() -> None:
    op.drop_table("companion_profiles")
