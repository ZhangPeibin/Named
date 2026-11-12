"""add challenges

Revision ID: 0015_challenges
Revises: 0014_experiences
Create Date: 2026-11-12 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0015_challenges"
down_revision: str | Sequence[str] | None = "0014_experiences"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "challenges",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("planned_days", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("started_at", sa.DateTime(), nullable=False),
        sa.Column("ended_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_challenges_account_id"), "challenges", ["account_id"])

    op.create_table(
        "challenge_items",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("challenge_id", sa.String(length=36), nullable=False),
        sa.Column("discovery_id", sa.String(length=36), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("visited_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["challenge_id"], ["challenges.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["discovery_id"], ["discoveries.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "challenge_id",
            "discovery_id",
            name="uq_challenge_items_challenge_discovery",
        ),
    )
    op.create_index(op.f("ix_challenge_items_challenge_id"), "challenge_items", ["challenge_id"])
    op.create_index(op.f("ix_challenge_items_discovery_id"), "challenge_items", ["discovery_id"])


def downgrade() -> None:
    op.drop_index(op.f("ix_challenge_items_discovery_id"), table_name="challenge_items")
    op.drop_index(op.f("ix_challenge_items_challenge_id"), table_name="challenge_items")
    op.drop_table("challenge_items")
    op.drop_index(op.f("ix_challenges_account_id"), table_name="challenges")
    op.drop_table("challenges")
