import hashlib
from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from agents import AgentFailed
from ai import AINotConfigured
from clock import utcnow
from companion.presence_agent import PresenceAgent, PresenceContext
from companion.schemas import PresenceOut
from companion.service import get_companion
from config import Settings
from learner.context import build_learner_context
from models import CompanionPresence, Conversation, MemoryItem

CACHE_TTL = timedelta(minutes=15)
MAX_WORD_CHARS = 64


def _time_bucket(hour: int) -> str:
    if 5 <= hour < 12:
        return "morning"
    if 12 <= hour < 18:
        return "afternoon"
    if 18 <= hour < 22:
        return "evening"
    return "night"


def _variant(account_id: str, day: str, key: str) -> int:
    digest = hashlib.sha256(f"{account_id}:{day}:{key}".encode()).digest()
    return digest[0] % 3


async def _recent_word(
    session: AsyncSession,
    account_id: str,
) -> MemoryItem | None:
    return await session.scalar(
        select(MemoryItem)
        .where(
            MemoryItem.account_id == account_id,
            MemoryItem.scope == "learned",
            MemoryItem.kind == "word",
            MemoryItem.status == "active",
            MemoryItem.deleted_at.is_(None),
        )
        .order_by(MemoryItem.last_seen_at.desc())
        .limit(1)
    )


async def _last_talk(
    session: AsyncSession,
    account_id: str,
) -> Conversation | None:
    return await session.scalar(
        select(Conversation)
        .where(Conversation.account_id == account_id)
        .order_by(Conversation.started_at.desc())
        .limit(1)
    )


def _to_out(row: CompanionPresence) -> PresenceOut:
    return PresenceOut(
        key=row.key,
        variant=row.variant,
        params=dict(row.params_json or {}),
    )


async def get_presence(
    session: AsyncSession,
    account_id: str,
    local_hour: int,
    agent: PresenceAgent,
    settings: Settings,
) -> PresenceOut:
    now = utcnow()
    cached = await session.get(CompanionPresence, account_id)
    if cached is not None and cached.expires_at > now:
        return _to_out(cached)

    time_bucket = _time_bucket(local_hour)
    companion = await get_companion(session, account_id)
    learner_context = await build_learner_context(
        session,
        account_id,
        focus_context="",
        user_text="",
        settings=settings,
    )
    word = await _recent_word(session, account_id)
    talk = await _last_talk(session, account_id)

    last_seen = talk.started_at if talk is not None else None
    if word is not None and word.last_seen_at is not None:
        if last_seen is None or word.last_seen_at > last_seen:
            last_seen = word.last_seen_at
    days_since = (now - last_seen).days if last_seen is not None else None
    returning = days_since is not None and days_since >= 3

    try:
        context = await agent.analyze(
            time_bucket=time_bucket,
            learner_context=learner_context,
            companion_name=companion.name,
            companion_hobby=companion.hobby,
            recent_word=word.text if word is not None else None,
            days_since_last_talk=days_since,
        )
    except (AINotConfigured, AgentFailed):
        context = PresenceContext()

    key = time_bucket
    params: dict[str, str] = {}
    if returning:
        key = "returning"
    elif context.topic == "recent_word" and word is not None:
        key = "word"
        params["word"] = word.text[:MAX_WORD_CHARS]
    elif context.topic == "recent_talk" and talk is not None:
        key = "talk"
    elif context.topic == "hobby" and companion.hobby:
        key = "hobby"

    variant = _variant(account_id, now.date().isoformat(), key)
    if cached is None:
        cached = CompanionPresence(account_id=account_id)
        session.add(cached)
    cached.key = key
    cached.variant = variant
    cached.params_json = params
    cached.generated_at = now
    cached.expires_at = now + CACHE_TTL
    await session.commit()
    return PresenceOut(key=key, variant=variant, params=params)
