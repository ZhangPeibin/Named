from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from errors import ApiError
from experience.schemas import (
    ExperienceDetailOut,
    ExperienceListItem,
    ExperienceListOut,
    ExperienceSourceOut,
)
from models import Conversation, Discovery, Experience, ExperienceSource, Word


def _parse_before(value: str | None) -> datetime | None:
    if value is None or not value.strip():
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ApiError("Invalid history cursor.", status_code=400, code="invalid_cursor") from exc
    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(UTC).replace(tzinfo=None)
    return parsed


def _scene_title(discovery: Discovery | None) -> str:
    if discovery is None:
        return "Moment"
    if discovery.scene_payload_json:
        natural = discovery.scene_payload_json.get("natural_english")
        if isinstance(natural, str) and natural.strip():
            return natural.strip()
    if discovery.input_text and discovery.input_text.strip():
        return discovery.input_text.strip()
    return "Moment"


async def _focus_info(
    session: AsyncSession,
    account_id: str,
    conversation: Conversation,
) -> tuple[str, str, str]:
    if conversation.focus_type == "word":
        word = await session.get(Word, conversation.focus_id)
        return "word", conversation.focus_id, word.label_en if word is not None else "Word"
    if conversation.focus_type == "scene":
        discovery = await session.get(Discovery, conversation.focus_id)
        if discovery is not None and discovery.account_id != account_id:
            discovery = None
        return "scene", conversation.focus_id, _scene_title(discovery)
    return conversation.focus_type, conversation.focus_id, "Conversation"


async def _item(
    session: AsyncSession,
    account_id: str,
    experience: Experience,
    focus: tuple[str, str, str],
) -> ExperienceListItem:
    focus_type, focus_id, focus_title = focus
    return ExperienceListItem(
        id=experience.id,
        kind=experience.kind,
        summary=experience.summary,
        detail=experience.detail,
        confidence=experience.confidence,
        created_at=experience.created_at,
        focus_type=focus_type,
        focus_id=focus_id,
        focus_title=focus_title,
        conversation_id=experience.conversation_id,
    )


async def list_experiences(
    session: AsyncSession,
    account_id: str,
    *,
    before: str | None = None,
    limit: int = 20,
) -> ExperienceListOut:
    before_at = _parse_before(before)
    query = select(Experience).where(
        Experience.account_id == account_id,
        Experience.deleted_at.is_(None),
    )
    if before_at is not None:
        query = query.where(Experience.created_at < before_at)
    experiences = list(
        await session.scalars(query.order_by(Experience.created_at.desc()).limit(limit + 1))
    )
    has_more = len(experiences) > limit
    experiences = experiences[:limit]
    if not experiences:
        return ExperienceListOut(items=[])

    conversation_ids = {item.conversation_id for item in experiences}
    conversations = {
        row.id: row
        for row in await session.scalars(
            select(Conversation).where(
                Conversation.id.in_(conversation_ids),
                Conversation.account_id == account_id,
            )
        )
    }

    focus_cache: dict[tuple[str, str], tuple[str, str, str]] = {}
    items: list[ExperienceListItem] = []
    for experience in experiences:
        conversation = conversations.get(experience.conversation_id)
        if conversation is None:
            continue
        key = (conversation.focus_type, conversation.focus_id)
        if key not in focus_cache:
            focus_cache[key] = await _focus_info(session, account_id, conversation)
        items.append(await _item(session, account_id, experience, focus_cache[key]))

    next_cursor = None
    if has_more and experiences:
        next_cursor = experiences[-1].created_at.isoformat()
    return ExperienceListOut(items=items, next_cursor=next_cursor)


async def get_experience(
    session: AsyncSession,
    account_id: str,
    experience_id: str,
) -> ExperienceDetailOut:
    experience = await session.scalar(
        select(Experience).where(
            Experience.id == experience_id,
            Experience.account_id == account_id,
            Experience.deleted_at.is_(None),
        )
    )
    if experience is None:
        raise ApiError("Experience not found.", status_code=404, code="experience_not_found")
    conversation = await session.get(Conversation, experience.conversation_id)
    if conversation is None or conversation.account_id != account_id:
        raise ApiError("Experience not found.", status_code=404, code="experience_not_found")
    focus = await _focus_info(session, account_id, conversation)
    sources = [
        ExperienceSourceOut(
            source_type=source.source_type,
            source_id=source.source_id,
            quote=source.quote,
        )
        for source in await session.scalars(
            select(ExperienceSource)
            .where(ExperienceSource.experience_id == experience.id)
            .order_by(ExperienceSource.created_at)
        )
    ]
    item = await _item(session, account_id, experience, focus)
    return ExperienceDetailOut(**item.model_dump(), sources=sources)
