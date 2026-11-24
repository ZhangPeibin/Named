"""add memory scope and backfill about items

Revision ID: 0028_memory_scope
Revises: 0027_memory_lifecycle
Create Date: 2026-11-23 19:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0028_memory_scope"
down_revision: str | Sequence[str] | None = "0027_memory_lifecycle"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "memory_items",
        sa.Column("scope", sa.String(length=16), nullable=False, server_default="learned"),
    )
    op.execute(
        """
        INSERT INTO memory_items (
            id, account_id, scope, kind, text, canonical_key, source_type,
            source_id, confidence, importance, mention_count, first_seen_at,
            last_seen_at, status, valid_from, created_at, updated_at
        )
        SELECT
            UUID(), account_id, 'about', kind, text,
            SHA2(CONCAT(kind, ':', LOWER(TRIM(text))), 256),
            source, 'backfill', 0.9, 0.6, 1, created_at, created_at,
            'active', created_at, created_at, created_at
        FROM soul_items
        WHERE deleted_at IS NULL
        """
    )


def downgrade() -> None:
    op.execute("DELETE FROM memory_items WHERE scope = 'about'")
    op.drop_column("memory_items", "scope")
