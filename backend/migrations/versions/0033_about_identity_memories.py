"""move conversational identity and preference memories to about

Revision ID: 0033_about_identity_memories
Revises: 0032_companion_presence
Create Date: 2026-11-26 00:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0033_about_identity_memories"
down_revision: str | Sequence[str] | None = "0032_companion_presence"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        "UPDATE memory_items SET scope = 'about' "
        "WHERE scope = 'learned' AND kind IN ('identity', 'preference') "
        "AND source_type = 'conversation_message'"
    )


def downgrade() -> None:
    op.execute(
        "UPDATE memory_items SET scope = 'learned' "
        "WHERE scope = 'about' AND kind IN ('identity', 'preference') "
        "AND source_type = 'conversation_message'"
    )
