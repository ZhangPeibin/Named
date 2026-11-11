import logging

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from media import MediaStore
from models import (
    Account,
    AuthCode,
    AuthSession,
    Conversation,
    ConversationMessage,
    Discovery,
    DiscoveryCandidate,
    ErrorPattern,
    Experience,
    ExperienceJob,
    ExperienceSource,
    MemoryItem,
    MessageAnnotation,
    MessageCorrection,
    SoulItem,
    SoulProfile,
    WordProgress,
)

logger = logging.getLogger(__name__)


async def purge_expired_deletions(session: AsyncSession, store: MediaStore) -> int:
    accounts = list(
        await session.scalars(
            select(Account).where(
                Account.deleted_at.is_not(None),
                Account.deletion_scheduled_at <= utcnow(),
            )
        )
    )

    purged = 0
    for account in accounts:
        discoveries = list(
            await session.scalars(select(Discovery).where(Discovery.account_id == account.id))
        )
        conversations = list(
            await session.scalars(select(Conversation).where(Conversation.account_id == account.id))
        )
        conversation_ids = [conversation.id for conversation in conversations]
        messages = []
        if conversation_ids:
            messages = list(
                await session.scalars(
                    select(ConversationMessage).where(
                        ConversationMessage.conversation_id.in_(conversation_ids)
                    )
                )
            )
        message_ids = [message.id for message in messages]

        for discovery in discoveries:
            for key, label in (
                (discovery.image_key, "discovery image"),
                (discovery.scene_audio_key, "discovery scene audio"),
            ):
                if not key:
                    continue
                try:
                    await store.delete(key)
                except Exception:
                    logger.warning("Could not delete %s during purge.", label)
        for message in messages:
            if message.audio_key:
                try:
                    await store.delete(message.audio_key)
                except Exception:
                    logger.warning("Could not delete message audio during purge.")

        if message_ids:
            await session.execute(
                delete(MessageCorrection).where(MessageCorrection.message_id.in_(message_ids))
            )
            await session.execute(
                delete(MessageAnnotation).where(MessageAnnotation.message_id.in_(message_ids))
            )
        if conversation_ids:
            await session.execute(
                delete(ConversationMessage).where(
                    ConversationMessage.conversation_id.in_(conversation_ids)
                )
            )
            await session.execute(delete(Conversation).where(Conversation.id.in_(conversation_ids)))

        discovery_ids = [discovery.id for discovery in discoveries]
        if discovery_ids:
            await session.execute(
                delete(DiscoveryCandidate).where(DiscoveryCandidate.discovery_id.in_(discovery_ids))
            )
            await session.execute(delete(Discovery).where(Discovery.id.in_(discovery_ids)))

        experience_ids = list(
            await session.scalars(select(Experience.id).where(Experience.account_id == account.id))
        )
        if experience_ids:
            await session.execute(
                delete(ExperienceSource).where(ExperienceSource.experience_id.in_(experience_ids))
            )
        await session.execute(delete(Experience).where(Experience.account_id == account.id))
        await session.execute(delete(ExperienceJob).where(ExperienceJob.account_id == account.id))
        await session.execute(delete(WordProgress).where(WordProgress.account_id == account.id))
        await session.execute(delete(MemoryItem).where(MemoryItem.account_id == account.id))
        await session.execute(delete(ErrorPattern).where(ErrorPattern.account_id == account.id))
        await session.execute(delete(SoulItem).where(SoulItem.account_id == account.id))
        await session.execute(delete(SoulProfile).where(SoulProfile.account_id == account.id))
        await session.execute(delete(AuthSession).where(AuthSession.account_id == account.id))
        await session.execute(delete(AuthCode).where(AuthCode.email == account.email))
        await session.execute(delete(Account).where(Account.id == account.id))
        purged += 1

    await session.commit()
    return purged
