import logging

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ai import AINotConfigured
from clock import utcnow
from config import Settings
from discovery.schemas import WordPayload
from errors import ApiError
from memory.service import correction_candidates, get_memory_context, record_memories
from models import (
    Conversation,
    ConversationMessage,
    Discovery,
    MessageAnnotation,
    MessageCorrection,
    SoulItem,
    SoulProfile,
    Word,
    WordContent,
)
from talk.agent import AgentFailed, HelpAgent, TalkAgent
from talk.schemas import (
    AnnotationOut,
    ConversationCreate,
    ConversationOut,
    CorrectionOut,
    EndConversationOut,
    HelpRequest,
    HelpResponse,
    MessageCreate,
    MessageOut,
    TurnOut,
)
from tts.schemas import SpeechAudioOut
from tts.service import SpeechAudioService

logger = logging.getLogger(__name__)


async def _get_conversation(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
) -> Conversation:
    conversation = await session.scalar(
        select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.account_id == account_id,
        )
    )
    if conversation is None:
        raise ApiError("Conversation not found.", status_code=404, code="conversation_not_found")
    return conversation


async def _native_language(session: AsyncSession, account_id: str) -> str:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        raise ApiError("Soul not found.", status_code=404, code="soul_not_found")
    return profile.native_language


async def _validate_focus(
    session: AsyncSession,
    account_id: str,
    focus_type: str,
    focus_id: str,
) -> None:
    if focus_type == "word":
        word = await session.get(Word, focus_id)
        if word is None:
            raise ApiError("Focus not found.", status_code=404, code="focus_not_found")
        linked = await session.scalar(
            select(Discovery.id)
            .where(
                Discovery.account_id == account_id,
                Discovery.word_id == focus_id,
                Discovery.deleted_at.is_(None),
            )
            .limit(1)
        )
        if linked is None:
            raise ApiError("Focus not found.", status_code=404, code="focus_not_found")
        return

    if focus_type == "scene":
        discovery = await session.get(Discovery, focus_id)
        if (
            discovery is None
            or discovery.account_id != account_id
            or discovery.deleted_at is not None
            or discovery.focus_kind != "scene"
        ):
            raise ApiError("Focus not found.", status_code=404, code="focus_not_found")
        return

    raise ApiError("Unsupported focus type.", code="invalid_focus_type")


async def _focus_context(
    session: AsyncSession,
    conversation: Conversation,
    native_language: str,
    settings: Settings,
) -> str:
    if conversation.focus_type == "word":
        word = await session.get(Word, conversation.focus_id)
        if word is None:
            return "Word: (missing)"
        content = await session.scalar(
            select(WordContent)
            .where(
                WordContent.word_id == word.id,
                WordContent.native_language == native_language,
                WordContent.model == settings.ai_model,
                WordContent.prompt_version == settings.ai_prompt_version,
            )
            .order_by(WordContent.created_at.desc())
            .limit(1)
        )
        if content is None:
            return f"Word: {word.label_en}"
        payload = WordPayload.model_validate(content.payload_json)
        sense = payload.senses[0] if payload.senses else None
        parts = [f"Word: {word.label_en}"]
        if payload.pos:
            parts.append(f"Part of speech: {', '.join(payload.pos)}")
        if sense is not None:
            parts.append(f"Simple definition: {sense.definition_en}")
            parts.append(f"Example: {sense.example_en}")
        if payload.grammar:
            parts.append(f"Grammar: {payload.grammar}")
        return "\n".join(parts)

    discovery = await session.get(Discovery, conversation.focus_id)
    if discovery is None:
        return "Scene: (missing)"
    parts = ["Scene focus"]
    if discovery.input_text:
        parts.append(f"Learner input: {discovery.input_text}")
    if discovery.context:
        parts.append(f"Context: {discovery.context}")
    return "\n".join(parts)


async def _soul_context(session: AsyncSession, account_id: str) -> str:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        return ""
    parts = [f"Native language: {profile.native_language}"]
    if profile.age is not None:
        parts.append(f"Age (learner-provided, do not infer from it): {profile.age}")
    if profile.gender is not None:
        parts.append(f"Gender (learner-provided, do not infer from it): {profile.gender}")

    items = await session.scalars(
        select(SoulItem)
        .where(SoulItem.account_id == account_id, SoulItem.deleted_at.is_(None))
        .order_by(SoulItem.created_at)
    )
    for item in items:
        parts.append(f"{item.kind}: {item.text} (source: {item.source})")
    return "\n".join(parts)


async def _history(
    session: AsyncSession,
    conversation_id: str,
    before_sequence: int | None = None,
    limit: int = 20,
) -> list[dict[str, str]]:
    query = select(ConversationMessage).where(
        ConversationMessage.conversation_id == conversation_id
    )
    if before_sequence is not None:
        query = query.where(ConversationMessage.sequence < before_sequence)
    rows = await session.scalars(query.order_by(ConversationMessage.sequence.desc()).limit(limit))
    return [{"role": row.role, "text": row.text} for row in reversed(list(rows))]


async def _message_out(
    session: AsyncSession,
    message: ConversationMessage,
    settings: Settings,
) -> MessageOut:
    corrections = await session.scalars(
        select(MessageCorrection)
        .where(MessageCorrection.message_id == message.id)
        .order_by(MessageCorrection.created_at)
    )
    annotations = await session.scalars(
        select(MessageAnnotation)
        .where(MessageAnnotation.message_id == message.id)
        .order_by(MessageAnnotation.created_at)
    )

    audio = None
    if message.role == "assistant" and message.audio_key:
        audio = SpeechAudioOut(
            url=f"{settings.media_url_prefix.rstrip('/')}/{message.audio_key}",
            status="ready",
        )

    return MessageOut(
        id=message.id,
        role=message.role,
        text=message.text,
        native_text=message.native_text,
        source=message.source,
        transcript_state=message.transcript_state,
        status=message.status,
        audio=audio,
        corrections=[CorrectionOut.model_validate(row) for row in corrections],
        annotations=[AnnotationOut.model_validate(row) for row in annotations],
        created_at=message.created_at,
    )


async def _conversation_title(
    session: AsyncSession,
    conversation: Conversation,
) -> str:
    if conversation.focus_type == "word":
        word = await session.get(Word, conversation.focus_id)
        if word is not None:
            return word.label_en
    elif conversation.focus_type == "scene":
        discovery = await session.get(Discovery, conversation.focus_id)
        if discovery is not None:
            if discovery.scene_payload_json:
                natural_english = discovery.scene_payload_json.get("natural_english")
                if isinstance(natural_english, str) and natural_english.strip():
                    return natural_english.strip()
            if discovery.input_text:
                return discovery.input_text.strip() or "Conversation"
    return "Conversation"


async def _conversation_out(
    session: AsyncSession,
    conversation: Conversation,
    settings: Settings,
) -> ConversationOut:
    messages = await session.scalars(
        select(ConversationMessage)
        .where(ConversationMessage.conversation_id == conversation.id)
        .order_by(ConversationMessage.sequence)
    )
    return ConversationOut(
        id=conversation.id,
        title=await _conversation_title(session, conversation),
        focus_type=conversation.focus_type,
        focus_id=conversation.focus_id,
        status=conversation.status,
        started_at=conversation.started_at,
        ended_at=conversation.ended_at,
        messages=[await _message_out(session, row, settings) for row in messages],
    )


async def create_conversation(
    session: AsyncSession,
    account_id: str,
    payload: ConversationCreate,
    settings: Settings,
) -> ConversationOut:
    await _validate_focus(session, account_id, payload.focus_type, payload.focus_id)
    conversation = Conversation(
        account_id=account_id,
        focus_type=payload.focus_type,
        focus_id=payload.focus_id,
        status="active",
    )
    session.add(conversation)
    await session.commit()
    await session.refresh(conversation)
    return await _conversation_out(session, conversation, settings)


async def get_conversation(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
    settings: Settings,
) -> ConversationOut:
    conversation = await _get_conversation(session, account_id, conversation_id)
    return await _conversation_out(session, conversation, settings)


async def _next_sequence(session: AsyncSession, conversation_id: str) -> int:
    current = await session.scalar(
        select(func.max(ConversationMessage.sequence)).where(
            ConversationMessage.conversation_id == conversation_id
        )
    )
    return (current or 0) + 1


async def send_message(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
    payload: MessageCreate,
    agent: TalkAgent,
    speech_service: SpeechAudioService,
    settings: Settings,
) -> TurnOut:
    conversation = await _get_conversation(session, account_id, conversation_id)
    if conversation.status != "active":
        raise ApiError("Conversation has ended.", status_code=409, code="conversation_ended")
    if payload.source == "voice" and not payload.transcript_confirmed:
        raise ApiError(
            "Voice transcript must be confirmed before sending.",
            code="transcript_unconfirmed",
        )

    user_message = await session.scalar(
        select(ConversationMessage).where(
            ConversationMessage.conversation_id == conversation_id,
            ConversationMessage.client_message_id == payload.client_message_id,
        )
    )

    if user_message is None:
        user_message = ConversationMessage(
            conversation_id=conversation_id,
            sequence=await _next_sequence(session, conversation_id),
            role="user",
            text=payload.text,
            source=payload.source,
            transcript_state="confirmed",
            status="saved",
            client_message_id=payload.client_message_id,
        )
        session.add(user_message)
        await session.commit()
        await session.refresh(user_message)
    else:
        assistant = await session.scalar(
            select(ConversationMessage).where(
                ConversationMessage.conversation_id == conversation_id,
                ConversationMessage.sequence == user_message.sequence + 1,
                ConversationMessage.role == "assistant",
            )
        )
        if assistant is not None:
            return TurnOut(
                user_message=await _message_out(session, user_message, settings),
                assistant_message=await _message_out(session, assistant, settings),
            )

    native_language = await _native_language(session, account_id)
    focus_context = await _focus_context(session, conversation, native_language, settings)
    soul_context = await _soul_context(session, account_id)
    memory_context = await get_memory_context(
        session,
        account_id,
        focus_context=focus_context,
        user_text=user_message.text,
    )
    history = await _history(session, conversation_id, before_sequence=user_message.sequence)

    try:
        response = await agent.respond(
            native_language=native_language,
            focus_context=focus_context,
            soul_context=soul_context,
            memory_context=memory_context,
            history=history,
            user_text=user_message.text,
        )
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
    except AgentFailed as exc:
        raise ApiError(
            "The conversation agent failed.",
            status_code=502,
            code="talk_agent_failed",
        ) from exc

    native_text = (response.native_reply or "").strip() or None
    if native_language.lower().startswith("en"):
        native_text = None

    assistant = ConversationMessage(
        conversation_id=conversation_id,
        sequence=user_message.sequence + 1,
        role="assistant",
        text=response.reply,
        native_text=native_text,
        source="text",
        transcript_state="confirmed",
        status="saved",
    )
    session.add(assistant)
    await session.flush()

    for correction in response.corrections:
        session.add(
            MessageCorrection(
                message_id=user_message.id,
                original=correction.original,
                suggestion=correction.suggestion,
                note=correction.note,
            )
        )
    for annotation in response.annotations:
        session.add(
            MessageAnnotation(
                message_id=assistant.id,
                text=annotation.text,
                kind=annotation.kind,
                meaning_zh=annotation.meaning_zh,
                part_of_speech=annotation.part_of_speech,
                grammar=annotation.grammar,
            )
        )

    _, audio_key = await speech_service.synthesize(session, response.reply)
    if audio_key is not None:
        assistant.audio_key = audio_key

    try:
        async with session.begin_nested():
            await record_memories(
                session,
                account_id,
                [*response.memories, *correction_candidates(response.corrections)],
                source_type="conversation_message",
                source_id=user_message.id,
            )
    except Exception:
        logger.warning("Companion memory update failed")

    await session.commit()
    await session.refresh(assistant)

    return TurnOut(
        user_message=await _message_out(session, user_message, settings),
        assistant_message=await _message_out(session, assistant, settings),
    )


async def end_conversation(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
) -> EndConversationOut:
    conversation = await _get_conversation(session, account_id, conversation_id)
    if conversation.status != "ended":
        conversation.status = "ended"
        conversation.ended_at = utcnow()
        await session.commit()
        await session.refresh(conversation)
    return EndConversationOut(
        id=conversation.id,
        status=conversation.status,
        ended_at=conversation.ended_at,
    )


async def help_expression(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
    payload: HelpRequest,
    agent: HelpAgent,
    speech_service: SpeechAudioService,
    settings: Settings,
) -> HelpResponse:
    conversation = await _get_conversation(session, account_id, conversation_id)
    native_language = await _native_language(session, account_id)
    focus_context = await _focus_context(session, conversation, native_language, settings)
    soul_context = await _soul_context(session, account_id)
    memory_context = await get_memory_context(
        session,
        account_id,
        focus_context=focus_context,
        user_text=payload.text,
    )
    history = await _history(session, conversation_id)

    try:
        suggestion = await agent.suggest(
            native_language=native_language,
            focus_context=focus_context,
            soul_context=soul_context,
            memory_context=memory_context,
            history=history,
            user_text=payload.text,
        )
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
    except AgentFailed as exc:
        raise ApiError(
            "The expression helper failed.",
            status_code=502,
            code="help_agent_failed",
        ) from exc

    audio, _ = await speech_service.synthesize(session, suggestion.natural_english)
    await session.commit()

    return HelpResponse(
        natural_english=suggestion.natural_english,
        note=suggestion.note,
        alternatives=suggestion.alternatives,
        audio=audio,
    )
