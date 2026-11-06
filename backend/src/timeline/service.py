from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from discovery.schemas import WordPayload
from errors import ApiError
from models import (
    Conversation,
    ConversationMessage,
    Discovery,
    SoulProfile,
    Word,
    WordContent,
)
from timeline.schemas import (
    TimelineResponse,
    TimelineTalkItem,
    TimelineTalkMessage,
    TimelineWordItem,
)
from tts.service import WordAudioService


def _parse_before(value: str | None) -> datetime | None:
    if value is None or not value.strip():
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ApiError(
            "Invalid timeline cursor.",
            status_code=400,
            code="invalid_cursor",
        ) from exc
    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(UTC).replace(tzinfo=None)
    return parsed


async def _native_language(session: AsyncSession, account_id: str) -> str:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        raise ApiError("Soul not found.", status_code=404, code="soul_not_found")
    return profile.native_language


async def _word_items(
    session: AsyncSession,
    account_id: str,
    audio_service: WordAudioService,
    *,
    limit: int,
    before: datetime | None,
) -> list[TimelineWordItem]:
    query = select(Discovery).where(
        Discovery.account_id == account_id,
        Discovery.deleted_at.is_(None),
        Discovery.status == "ready",
        Discovery.focus_kind == "word",
        Discovery.word_id.is_not(None),
    )
    if before is not None:
        query = query.where(Discovery.created_at < before)

    rows = list(await session.scalars(query.order_by(Discovery.created_at.desc()).limit(limit)))
    if not rows:
        return []

    word_ids = {row.word_id for row in rows if row.word_id is not None}
    native_language = await _native_language(session, account_id)

    content_by_word: dict[str, WordContent] = {}
    if word_ids:
        contents = await session.scalars(
            select(WordContent)
            .where(
                WordContent.word_id.in_(word_ids),
                WordContent.native_language == native_language,
            )
            .order_by(WordContent.created_at.desc())
        )
        for content in contents:
            content_by_word.setdefault(content.word_id, content)

    words_by_id = {}
    if word_ids:
        words = await session.scalars(select(Word).where(Word.id.in_(word_ids)))
        words_by_id = {word.id: word for word in words}

    conversation_by_word: dict[str, str] = {}
    if word_ids:
        conversations = await session.scalars(
            select(Conversation)
            .where(
                Conversation.account_id == account_id,
                Conversation.focus_type == "word",
                Conversation.focus_id.in_(word_ids),
            )
            .order_by(Conversation.started_at.desc())
        )
        for conversation in conversations:
            conversation_by_word.setdefault(conversation.focus_id, conversation.id)

    items: list[TimelineWordItem] = []
    for row in rows:
        if row.word_id is None:
            continue
        content = content_by_word.get(row.word_id)
        if content is None:
            continue
        word = WordPayload.model_validate(content.payload_json)
        word_row = words_by_id.get(row.word_id)
        audio = await audio_service.for_word(session, word_row) if word_row is not None else None
        items.append(
            TimelineWordItem(
                id=row.id,
                created_at=row.created_at,
                input_text=row.input_text,
                status=row.status,
                focus_kind=row.focus_kind,
                word_id=row.word_id,
                word=word,
                audio=audio,
                conversation_id=conversation_by_word.get(row.word_id),
            )
        )
    return items


async def _talk_items(
    session: AsyncSession,
    account_id: str,
    *,
    limit: int,
    before: datetime | None,
) -> list[TimelineTalkItem]:
    stats = (
        select(
            ConversationMessage.conversation_id.label("conversation_id"),
            func.min(ConversationMessage.created_at).label("first_at"),
            func.count(ConversationMessage.id).label("message_count"),
        )
        .group_by(ConversationMessage.conversation_id)
        .subquery()
    )

    query = (
        select(
            Conversation,
            stats.c.first_at,
            stats.c.message_count,
        )
        .join(stats, stats.c.conversation_id == Conversation.id)
        .where(Conversation.account_id == account_id)
    )
    if before is not None:
        query = query.where(stats.c.first_at < before)

    rows = (await session.execute(query.order_by(stats.c.first_at.desc()).limit(limit))).all()
    if not rows:
        return []

    conversation_ids = [row[0].id for row in rows]
    messages = list(
        await session.scalars(
            select(ConversationMessage)
            .where(ConversationMessage.conversation_id.in_(conversation_ids))
            .order_by(
                ConversationMessage.conversation_id,
                ConversationMessage.sequence.desc(),
            )
        )
    )
    last_by_conversation: dict[str, ConversationMessage] = {}
    for message in messages:
        last_by_conversation.setdefault(message.conversation_id, message)

    word_ids = {row[0].focus_id for row in rows if row[0].focus_type == "word"}
    scene_ids = {row[0].focus_id for row in rows if row[0].focus_type == "scene"}

    word_labels: dict[str, str] = {}
    if word_ids:
        words = await session.scalars(select(Word).where(Word.id.in_(word_ids)))
        word_labels = {word.id: word.label_en for word in words}

    scene_inputs: dict[str, str] = {}
    if scene_ids:
        scenes = await session.scalars(
            select(Discovery).where(
                Discovery.id.in_(scene_ids),
                Discovery.account_id == account_id,
            )
        )
        for scene in scenes:
            scene_inputs[scene.id] = scene.input_text or "Scene"

    items: list[TimelineTalkItem] = []
    for conversation, first_at, message_count in rows:
        last_message = last_by_conversation.get(conversation.id)
        if last_message is None:
            continue
        title = (
            word_labels.get(conversation.focus_id)
            if conversation.focus_type == "word"
            else scene_inputs.get(conversation.focus_id)
        ) or "Talk"
        items.append(
            TimelineTalkItem(
                id=conversation.id,
                created_at=first_at,
                conversation_id=conversation.id,
                title=title,
                focus_type=conversation.focus_type,
                focus_id=conversation.focus_id,
                last_message=TimelineTalkMessage(
                    role=last_message.role,
                    text=last_message.text,
                    created_at=last_message.created_at,
                ),
                message_count=message_count,
            )
        )
    return items


async def get_timeline(
    session: AsyncSession,
    account_id: str,
    audio_service: WordAudioService,
    *,
    limit: int,
    before: str | None,
    item_type: str,
) -> TimelineResponse:
    before_at = _parse_before(before)
    word_items: list[TimelineWordItem] = []
    talk_items: list[TimelineTalkItem] = []

    if item_type in {"all", "word"}:
        word_items = await _word_items(
            session,
            account_id,
            audio_service,
            limit=limit,
            before=before_at,
        )
    if item_type in {"all", "talk"}:
        talk_items = await _talk_items(
            session,
            account_id,
            limit=limit,
            before=before_at,
        )

    items = sorted(
        [*word_items, *talk_items],
        key=lambda item: item.created_at,
        reverse=True,
    )[:limit]
    next_cursor = items[-1].created_at.isoformat() if len(items) == limit else None
    return TimelineResponse(items=items, next_cursor=next_cursor)
