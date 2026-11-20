"""add question threads

Revision ID: 0021_question_threads
Revises: 0020_questions
Create Date: 2026-11-16 00:00:00.000000
"""

from collections.abc import Sequence
from datetime import datetime
from uuid import uuid4

import sqlalchemy as sa
from alembic import op

revision: str = "0021_question_threads"
down_revision: str | Sequence[str] | None = "0020_questions"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "question_threads",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("context_type", sa.String(length=32), nullable=True),
        sa.Column("context_ref", sa.String(length=64), nullable=True),
        sa.Column("context_quote", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_question_threads_account_id"),
        "question_threads",
        ["account_id"],
    )
    op.create_table(
        "question_messages",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("thread_id", sa.String(length=36), nullable=False),
        sa.Column("role", sa.String(length=16), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("example", sa.Text(), nullable=True),
        sa.Column("native_explanation", sa.Text(), nullable=True),
        sa.Column("confidence", sa.String(length=16), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["thread_id"],
            ["question_threads.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_question_messages_thread_id"),
        "question_messages",
        ["thread_id"],
    )

    bind = op.get_bind()
    old_rows = bind.execute(
        sa.text(
            "SELECT id, account_id, question, answer, native_explanation, created_at "
            "FROM question_exchanges"
        )
    ).mappings()
    threads = sa.table(
        "question_threads",
        sa.column("id", sa.String),
        sa.column("account_id", sa.String),
        sa.column("title", sa.String),
        sa.column("context_type", sa.String),
        sa.column("context_ref", sa.String),
        sa.column("context_quote", sa.Text),
        sa.column("created_at", sa.DateTime),
        sa.column("updated_at", sa.DateTime),
        sa.column("deleted_at", sa.DateTime),
    )
    messages = sa.table(
        "question_messages",
        sa.column("id", sa.String),
        sa.column("thread_id", sa.String),
        sa.column("role", sa.String),
        sa.column("text", sa.Text),
        sa.column("example", sa.Text),
        sa.column("native_explanation", sa.Text),
        sa.column("confidence", sa.String),
        sa.column("created_at", sa.DateTime),
    )
    for row in old_rows:
        thread_id = str(uuid4())
        created_at = row["created_at"] or datetime.utcnow()
        bind.execute(
            threads.insert().values(
                id=thread_id,
                account_id=row["account_id"],
                title=row["question"][:200],
                created_at=created_at,
                updated_at=created_at,
            )
        )
        bind.execute(
            messages.insert(),
            [
                {
                    "id": str(uuid4()),
                    "thread_id": thread_id,
                    "role": "user",
                    "text": row["question"],
                    "created_at": created_at,
                },
                {
                    "id": str(uuid4()),
                    "thread_id": thread_id,
                    "role": "assistant",
                    "text": row["answer"],
                    "native_explanation": row["native_explanation"],
                    "confidence": "high",
                    "created_at": created_at,
                },
            ],
        )


def downgrade() -> None:
    op.drop_index(op.f("ix_question_messages_thread_id"), table_name="question_messages")
    op.drop_table("question_messages")
    op.drop_index(op.f("ix_question_threads_account_id"), table_name="question_threads")
    op.drop_table("question_threads")
