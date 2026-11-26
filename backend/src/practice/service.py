import random

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from agents.errors import AgentFailed, agent_api_error
from ai import AINotConfigured
from clock import utcnow
from discovery.schemas import WordPayload
from errors import ApiError
from models import Discovery, SoulProfile, Word, WordContent, WordProgress
from practice.agent import SPEC, PracticeAgent
from practice.schemas import (
    PracticeCompleteOut,
    PracticeReplyIn,
    PracticeReplyOut,
    PracticeWordOut,
)
from tts.service import WordAudioService


def practice_weight(practice_count: int) -> float:
    return 1.0 / (1 + practice_count)


def pick_weighted(word_ids: list[str], counts: dict[str, int]) -> str:
    weights = [practice_weight(counts.get(word_id, 0)) for word_id in word_ids]
    return random.choices(word_ids, weights=weights, k=1)[0]


async def _native_language(session: AsyncSession, account_id: str) -> str:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        raise ApiError("Soul not found.", status_code=404, code="soul_not_found")
    return profile.native_language


async def _owned_saved_word(
    session: AsyncSession,
    account_id: str,
    word_id: str,
) -> Word:
    word = await session.get(Word, word_id)
    linked = await session.scalar(
        select(Discovery.id)
        .where(
            Discovery.account_id == account_id,
            Discovery.word_id == word_id,
            Discovery.deleted_at.is_(None),
            Discovery.status == "ready",
            Discovery.focus_kind == "word",
        )
        .limit(1)
    )
    if word is None or linked is None:
        raise ApiError("Word not found.", status_code=404, code="word_not_found")
    return word


async def _saved_context(
    session: AsyncSession,
    account_id: str,
    word_id: str,
) -> str | None:
    return await session.scalar(
        select(
            func.coalesce(
                func.nullif(Discovery.context, ""),
                Discovery.input_text,
            )
        )
        .where(
            Discovery.account_id == account_id,
            Discovery.word_id == word_id,
            Discovery.deleted_at.is_(None),
            Discovery.status == "ready",
            Discovery.focus_kind == "word",
        )
        .order_by(Discovery.created_at.desc())
        .limit(1)
    )


async def _saved_words(session: AsyncSession, account_id: str) -> list[tuple[str, str]]:
    rows = await session.execute(
        select(Word.id, Word.label_en)
        .join(Discovery, Discovery.word_id == Word.id)
        .where(
            Discovery.account_id == account_id,
            Discovery.deleted_at.is_(None),
            Discovery.status == "ready",
            Discovery.focus_kind == "word",
            Discovery.word_id.is_not(None),
        )
        .group_by(Word.id, Word.label_en)
    )
    return [(row[0], row[1]) for row in rows.all()]


async def get_next_practice(
    session: AsyncSession,
    account_id: str,
    audio_service: WordAudioService,
) -> PracticeWordOut:
    saved = await _saved_words(session, account_id)
    if not saved:
        raise ApiError(
            "Save a word before practicing.",
            status_code=404,
            code="practice_no_words",
        )

    word_ids = [word_id for word_id, _ in saved]
    progress_rows = await session.scalars(
        select(WordProgress).where(
            WordProgress.account_id == account_id,
            WordProgress.word_id.in_(word_ids),
        )
    )
    counts = {progress.word_id: progress.practice_count for progress in progress_rows}

    chosen_id = pick_weighted(word_ids, counts)
    chosen_label = next(label for word_id, label in saved if word_id == chosen_id)

    word = await session.get(Word, chosen_id)
    if word is None:
        raise ApiError("Word not found.", status_code=404, code="word_not_found")

    native_language = await _native_language(session, account_id)
    content = await session.scalar(
        select(WordContent)
        .where(
            WordContent.word_id == chosen_id,
            WordContent.native_language == native_language,
            WordContent.content_level == "full",
        )
        .order_by(WordContent.created_at.desc())
        .limit(1)
    )
    context = await _saved_context(session, account_id, chosen_id)

    labels = list(
        dict.fromkeys(
            label for word_id, label in saved if word_id != chosen_id and label != chosen_label
        )
    )
    options = random.sample(labels, k=min(4, len(labels))) if labels else []

    return PracticeWordOut(
        id=chosen_id,
        label_en=word.label_en,
        content=(WordPayload.model_validate(content.payload_json) if content is not None else None),
        audio=await audio_service.for_word(session, word),
        context=context,
        options=options,
        practice_count=counts.get(chosen_id, 0),
    )


async def complete_practice(
    session: AsyncSession,
    account_id: str,
    word_id: str,
) -> PracticeCompleteOut:
    await _owned_saved_word(session, account_id, word_id)

    progress = await session.scalar(
        select(WordProgress).where(
            WordProgress.account_id == account_id,
            WordProgress.word_id == word_id,
        )
    )
    if progress is None:
        progress = WordProgress(account_id=account_id, word_id=word_id)
        session.add(progress)
        await session.flush()

    progress.practice_count += 1
    progress.last_practiced_at = utcnow()
    await session.commit()

    return PracticeCompleteOut(
        word_id=word_id,
        practice_count=progress.practice_count,
        last_practiced_at=progress.last_practiced_at,
    )


async def practice_reply(
    session: AsyncSession,
    account_id: str,
    word_id: str,
    payload: PracticeReplyIn,
    agent: PracticeAgent,
) -> PracticeReplyOut:
    word = await _owned_saved_word(session, account_id, word_id)
    context = await _saved_context(session, account_id, word_id)
    native_language = await _native_language(session, account_id)
    history = [{"role": item.role, "text": item.text} for item in payload.history]

    try:
        response = await agent.respond(
            word=word.label_en,
            context=context,
            native_language=native_language,
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
        raise agent_api_error(exc, SPEC) from exc

    native_reply = response.native_reply
    if native_language.lower().startswith("en"):
        native_reply = None

    return PracticeReplyOut(
        reply=response.reply,
        recast=response.recast,
        native_reply=native_reply,
    )
