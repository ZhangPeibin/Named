from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from models import Conversation, ConversationMessage, DailyReading, Discovery, WordProgress


async def get_progress(session: AsyncSession, account_id: str) -> tuple[int, int, int, int]:
    words = await session.scalar(
        select(func.count(func.distinct(Discovery.word_id))).where(
            Discovery.account_id == account_id,
            Discovery.deleted_at.is_(None),
            Discovery.status == "ready",
            Discovery.focus_kind == "word",
            Discovery.word_id.is_not(None),
        )
    )
    conversations = await session.scalar(
        select(func.count(func.distinct(ConversationMessage.conversation_id)))
        .select_from(ConversationMessage)
        .join(Conversation, Conversation.id == ConversationMessage.conversation_id)
        .where(Conversation.account_id == account_id)
    )
    readings = await session.scalar(
        select(func.count(DailyReading.id)).where(
            DailyReading.account_id == account_id,
            DailyReading.completed_at.is_not(None),
        )
    )
    practices = await session.scalar(
        select(func.coalesce(func.sum(WordProgress.practice_count), 0)).where(
            WordProgress.account_id == account_id
        )
    )
    return words or 0, conversations or 0, readings or 0, int(practices or 0)
