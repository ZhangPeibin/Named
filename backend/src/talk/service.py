import logging
import re

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from agents import AgentFailed, agent_api_error
from ai import AINotConfigured
from clock import utcnow
from companion.context import format_companion_context
from companion.service import get_companion, rename_companion
from config import Settings
from discovery.schemas import WordPayload
from errors import ApiError
from experience.service import enqueue_experience_job
from learner.context import build_learner_context
from memory.service import correction_candidates, record_memories
from models import (
    Conversation,
    ConversationMessage,
    Discovery,
    MessageAnnotation,
    MessageCorrection,
    SoulProfile,
    Word,
    WordContent,
    WordProgress,
)
from talk.agent import HELP_SPEC, OPENER_SPEC, HelpAgent, OpenerAgent, TalkAgent
from talk.agent import SPEC as TALK_SPEC
from talk.errors import record_error_profile
from talk.schemas import (
    AnnotationOut,
    ConversationCreate,
    ConversationOut,
    ConversationUpdate,
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


def _normalize_text(value: str) -> str:
    return " ".join(value.split()).lower()


def contains_term(text: str, term: str) -> bool:
    """Match a whole word or phrase, ignoring case and extra whitespace."""
    normalized_term = _normalize_text(term)
    if not normalized_term:
        return False
    pattern = rf"(?<![a-z]){re.escape(normalized_term)}(?![a-z])"
    return re.search(pattern, _normalize_text(text)) is not None


async def _word_terms(
    session: AsyncSession,
    account_id: str,
    word: Word,
) -> list[str]:
    terms = [word.label_en]
    content = await session.scalar(
        select(WordContent)
        .where(
            WordContent.word_id == word.id,
            WordContent.native_language == await _native_language(session, account_id),
            WordContent.content_level == "full",
        )
        .order_by(WordContent.created_at.desc())
    )
    if content is not None:
        payload = WordPayload.model_validate(content.payload_json)
        terms.extend(chunk.phrase for chunk in payload.chunks if chunk.phrase)
    return terms


async def _record_word_usage(
    session: AsyncSession,
    account_id: str,
    conversation: Conversation,
    text: str,
) -> None:
    if conversation.focus_type != "word" or not conversation.focus_id:
        return
    word = await session.get(Word, conversation.focus_id)
    if word is None:
        return
    if not any(contains_term(text, term) for term in await _word_terms(session, account_id, word)):
        return
    progress = await session.scalar(
        select(WordProgress).where(
            WordProgress.account_id == account_id,
            WordProgress.word_id == word.id,
        )
    )
    if progress is None:
        progress = WordProgress(account_id=account_id, word_id=word.id)
        session.add(progress)
    progress.used_count = (progress.used_count or 0) + 1
    progress.last_used_at = utcnow()
    await session.flush()


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
                WordContent.content_level == "full",
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
        english_text=message.english_text,
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
        use_memory=conversation.use_memory,
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
        use_memory=payload.use_memory,
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


async def open_conversation(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
    agent: OpenerAgent,
    speech_service: SpeechAudioService,
    settings: Settings,
) -> MessageOut:
    conversation = await _get_conversation(session, account_id, conversation_id)
    if conversation.status != "active":
        raise ApiError(
            "Conversation has ended.",
            status_code=409,
            code="conversation_ended",
        )
    first = await session.scalar(
        select(ConversationMessage)
        .where(ConversationMessage.conversation_id == conversation_id)
        .order_by(ConversationMessage.sequence)
        .limit(1)
    )
    if first is not None:
        if first.role == "assistant":
            return await _message_out(session, first, settings)
        raise ApiError(
            "Conversation already started.",
            status_code=409,
            code="conversation_already_started",
        )

    native_language = await _native_language(session, account_id)
    focus_context = await _focus_context(session, conversation, native_language, settings)
    learner_context = await build_learner_context(
        session,
        account_id,
        focus_context=focus_context,
        user_text="",
        settings=settings,
        use_memory=conversation.use_memory,
    )
    companion = await get_companion(session, account_id)
    prior_query = (
        select(func.count())
        .select_from(Conversation)
        .where(
            Conversation.account_id == account_id,
            Conversation.id != conversation_id,
        )
    )
    if companion.named_at is not None:
        prior_query = prior_query.where(
            Conversation.started_at >= companion.named_at,
        )
    prior = await session.scalar(prior_query)

    try:
        response = await agent.open(
            native_language=native_language,
            focus_context=focus_context,
            learner_context=learner_context,
            companion_name=companion.name,
            companion_gender=companion.gender,
            companion_hobby=companion.hobby,
            first_conversation=(prior or 0) == 0,
        )
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
    except AgentFailed as exc:
        raise agent_api_error(exc, OPENER_SPEC) from exc

    native_text = (response.native_reply or "").strip() or None
    if native_language.lower().startswith("en"):
        native_text = None

    assistant = ConversationMessage(
        conversation_id=conversation_id,
        sequence=1,
        role="assistant",
        text=response.reply,
        native_text=native_text,
        source="text",
        transcript_state="confirmed",
        status="saved",
    )
    session.add(assistant)
    await session.flush()
    _, audio_key = await speech_service.synthesize(session, response.reply)
    if audio_key is not None:
        assistant.audio_key = audio_key
    await session.commit()
    await session.refresh(assistant)
    return await _message_out(session, assistant, settings)


async def update_conversation(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
    payload: ConversationUpdate,
    settings: Settings,
) -> ConversationOut:
    conversation = await _get_conversation(session, account_id, conversation_id)
    conversation.use_memory = payload.use_memory
    await session.commit()
    await session.refresh(conversation)
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
        try:
            async with session.begin_nested():
                await _record_word_usage(session, account_id, conversation, payload.text)
        except Exception:
            logger.warning("Word usage update failed")
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
    learner_context = await build_learner_context(
        session,
        account_id,
        focus_context=focus_context,
        user_text=user_message.text,
        settings=settings,
        use_memory=conversation.use_memory,
    )
    history = await _history(session, conversation_id, before_sequence=user_message.sequence)
    companion_context = format_companion_context(await get_companion(session, account_id))

    try:
        response = await agent.respond(
            native_language=native_language,
            focus_context=focus_context,
            learner_context=learner_context,
            companion_context=companion_context,
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
        raise agent_api_error(exc, TALK_SPEC) from exc

    native_text = (response.native_reply or "").strip() or None
    if native_language.lower().startswith("en"):
        native_text = None

    user_english = (response.user_english or "").strip() or None
    if user_english and user_english != user_message.text.strip():
        user_message.english_text = user_english

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
                category=correction.category,
                pattern=correction.pattern,
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
                ipa=annotation.ipa,
                syllables=annotation.syllables,
                vowels=annotation.vowels,
                consonants=annotation.consonants,
                phonics=annotation.phonics,
            )
        )

    try:
        async with session.begin_nested():
            await record_error_profile(session, account_id, response.corrections)
    except Exception:
        logger.warning("Learner error profile update failed")

    _, audio_key = await speech_service.synthesize(session, response.reply)
    if audio_key is not None:
        assistant.audio_key = audio_key

    try:
        async with session.begin_nested():
            profile = await session.get(SoulProfile, account_id)
            extracted = list(response.memories) if profile is None or profile.auto_extract else []
            await record_memories(
                session,
                account_id,
                [*extracted, *correction_candidates(response.corrections)],
                source_type="conversation_message",
                source_id=user_message.id,
            )
    except Exception:
        logger.warning("Companion memory update failed")

    await session.commit()
    await session.refresh(assistant)

    renamed_name = None
    if response.companion_name:
        try:
            renamed = await rename_companion(
                session,
                account_id,
                response.companion_name,
            )
            renamed_name = renamed.name
        except ApiError:
            logger.warning("Companion rename rejected")

    try:
        await enqueue_experience_job(session, account_id, conversation_id, settings)
        await session.commit()
    except Exception:
        await session.rollback()
        logger.warning("Experience job enqueue failed")

    return TurnOut(
        user_message=await _message_out(session, user_message, settings),
        assistant_message=await _message_out(session, assistant, settings),
        companion_name=renamed_name,
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
    learner_context = await build_learner_context(
        session,
        account_id,
        focus_context=focus_context,
        user_text=payload.text,
        settings=settings,
        use_memory=conversation.use_memory,
    )
    history = await _history(session, conversation_id)
    companion_context = format_companion_context(await get_companion(session, account_id))

    try:
        suggestion = await agent.suggest(
            native_language=native_language,
            focus_context=focus_context,
            learner_context=learner_context,
            companion_context=companion_context,
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
        raise agent_api_error(exc, HELP_SPEC) from exc

    audio, _ = await speech_service.synthesize(session, suggestion.natural_english)
    await session.commit()

    return HelpResponse(
        natural_english=suggestion.natural_english,
        note=suggestion.note,
        alternatives=suggestion.alternatives,
        audio=audio,
    )
