"""add experiences, sources, and extraction jobs

Revision ID: 0014_experiences
Revises: 0013_user_message_english
Create Date: 2026-11-11 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0014_experiences"
down_revision: str | Sequence[str] | None = "0013_user_message_english"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "experiences",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("conversation_id", sa.String(length=36), nullable=False),
        sa.Column("kind", sa.String(length=16), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("detail", sa.Text(), nullable=True),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["conversation_id"], ["conversations.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "conversation_id",
            "kind",
            name="uq_experiences_conversation_kind",
        ),
    )
    op.create_index(op.f("ix_experiences_account_id"), "experiences", ["account_id"])
    op.create_index(op.f("ix_experiences_conversation_id"), "experiences", ["conversation_id"])

    op.create_table(
        "experience_sources",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("experience_id", sa.String(length=36), nullable=False),
        sa.Column("source_type", sa.String(length=32), nullable=False),
        sa.Column("source_id", sa.String(length=64), nullable=False),
        sa.Column("quote", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["experience_id"], ["experiences.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_experience_sources_experience_id"),
        "experience_sources",
        ["experience_id"],
    )

    op.create_table(
        "experience_jobs",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("conversation_id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False),
        sa.Column("available_at", sa.DateTime(), nullable=False),
        sa.Column("last_error_code", sa.String(length=64), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["conversation_id"], ["conversations.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("conversation_id"),
    )
    op.create_index(op.f("ix_experience_jobs_account_id"), "experience_jobs", ["account_id"])
    op.create_index(
        op.f("ix_experience_jobs_conversation_id"), "experience_jobs", ["conversation_id"]
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_experience_jobs_conversation_id"), table_name="experience_jobs")
    op.drop_index(op.f("ix_experience_jobs_account_id"), table_name="experience_jobs")
    op.drop_table("experience_jobs")
    op.drop_index(op.f("ix_experience_sources_experience_id"), table_name="experience_sources")
    op.drop_table("experience_sources")
    op.drop_index(op.f("ix_experiences_conversation_id"), table_name="experiences")
    op.drop_index(op.f("ix_experiences_account_id"), table_name="experiences")
    op.drop_table("experiences")
