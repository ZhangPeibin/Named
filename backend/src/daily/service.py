import re
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ai import AINotConfigured
from clock import utcnow
from config import Settings
from daily.agent import AgentFailed, DailyReadAgent
from daily.schemas import (
    DailyCompleteOut,
    DailyReadOut,
    DailyTranslationLineOut,
    DailyTranslationOut,
)
from daily.translation_agent import DailyTranslationAgent, TranslationFailed
from errors import ApiError
from models import DailyReading, Discovery, SoulProfile, Word
from tts.timed_provider import TimedSpeechError, TimedSpeechNotConfigured
from tts.timed_service import TimedSpeechService

_STARTER_WORDS = ["notice", "small", "today", "look", "quiet"]

_STORY_THEMES = [
    "a small misunderstanding",
    "something unexpected at home",
    "a quiet walk",
    "a tiny win",
    "a familiar object",
    "a change in the weather",
    "a conversation overheard",
    "a plan that changes",
    "a moment of courage",
    "a small kindness",
]


async def _native_language(session: AsyncSession, account_id: str) -> str:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        raise ApiError("Soul not found.", status_code=404, code="soul_not_found")
    return profile.native_language


async def _recent_words(session: AsyncSession, account_id: str) -> list[str]:
    rows = await session.scalars(
        select(Word.label_en)
        .join(Discovery, Discovery.word_id == Word.id)
        .where(
            Discovery.account_id == account_id,
            Discovery.deleted_at.is_(None),
        )
        .order_by(Discovery.created_at.desc())
        .limit(20)
    )
    words: list[str] = []
    for row in rows:
        label = row.strip()
        if label and label.lower() not in {word.lower() for word in words}:
            words.append(label)
        if len(words) >= 5:
            break
    return words or list(_STARTER_WORDS)


async def current_streak(session: AsyncSession, account_id: str) -> int:
    dates = set(
        await session.scalars(
            select(DailyReading.reading_date).where(
                DailyReading.account_id == account_id,
                DailyReading.completed_at.is_not(None),
            )
        )
    )
    cursor = utcnow().date()
    if cursor not in dates:
        cursor -= timedelta(days=1)
    streak = 0
    while cursor in dates:
        streak += 1
        cursor -= timedelta(days=1)
    return streak


async def ensure_daily_task(
    session: AsyncSession,
    *,
    account_id: str,
) -> DailyReading:
    today: date = utcnow().date()
    reading = await session.scalar(
        select(DailyReading).where(
            DailyReading.account_id == account_id,
            DailyReading.reading_date == today,
        )
    )
    if reading is not None:
        return reading
    reading = DailyReading(
        account_id=account_id,
        reading_date=today,
        title="",
        passage="",
        target_words_json=[],
        question=None,
    )
    session.add(reading)
    try:
        await session.commit()
    except IntegrityError:
        await session.rollback()
        reading = await session.scalar(
            select(DailyReading).where(
                DailyReading.account_id == account_id,
                DailyReading.reading_date == today,
            )
        )
        if reading is None:
            raise
    return reading


async def _pick_theme(session: AsyncSession, account_id: str) -> str:
    recent = list(
        await session.scalars(
            select(DailyReading.theme)
            .where(
                DailyReading.account_id == account_id,
                DailyReading.theme.is_not(None),
            )
            .order_by(DailyReading.created_at.desc())
            .limit(5)
        )
    )
    used = {theme for theme in recent if theme}
    for theme in _STORY_THEMES:
        if theme not in used:
            return theme
    return _STORY_THEMES[0]


async def _build_daily_out(
    session: AsyncSession,
    reading: DailyReading,
    timed_speech: TimedSpeechService,
    *,
    account_id: str,
) -> DailyReadOut:
    try:
        audio, words = await timed_speech.synthesize(session, reading.passage)
    except TimedSpeechNotConfigured as exc:
        raise ApiError(
            "Timed speech is not configured.",
            status_code=503,
            code="tts_not_configured",
        ) from exc
    except TimedSpeechError as exc:
        raise ApiError(
            "Timed speech synthesis failed.",
            status_code=502,
            code="tts_failed",
        ) from exc
    return DailyReadOut(
        date=reading.reading_date,
        title=reading.title,
        passage=reading.passage,
        target_words=list(reading.target_words_json or []),
        question=reading.question,
        audio=audio,
        words=[
            {
                "text": word.text,
                "start_char": word.start_char,
                "end_char": word.end_char,
                "begin_ms": word.begin_ms,
                "end_ms": word.end_ms,
            }
            for word in words
        ],
        completed=reading.completed_at is not None,
        streak=await current_streak(session, account_id),
        duration_seconds=reading.completed_duration_seconds,
    )


async def get_daily_read(
    session: AsyncSession,
    *,
    account_id: str,
    agent: DailyReadAgent,
    timed_speech: TimedSpeechService,
    settings: Settings,
    reading_date: date | None = None,
) -> DailyReadOut:
    today: date = utcnow().date()
    target_date = reading_date or today
    reading = await session.scalar(
        select(DailyReading).where(
            DailyReading.account_id == account_id,
            DailyReading.reading_date == target_date,
        )
    )

    if target_date != today:
        if reading is None or not reading.passage.strip():
            raise ApiError(
                "Daily reading not found.",
                status_code=404,
                code="daily_not_found",
            )
        result = await _build_daily_out(
            session,
            reading,
            timed_speech,
            account_id=account_id,
        )
        await session.commit()
        return result

    if reading is None:
        reading = DailyReading(
            account_id=account_id,
            reading_date=today,
            title="",
            passage="",
            target_words_json=[],
            question=None,
        )
        session.add(reading)
        await session.flush()

    if not reading.passage.strip():
        target_words = await _recent_words(session, account_id)
        native_language = await _native_language(session, account_id)
        theme = await _pick_theme(session, account_id)
        try:
            output = await agent.write(
                target_words=target_words,
                native_language=native_language,
                theme=theme,
            )
        except AINotConfigured as exc:
            raise ApiError(
                "AI provider is not configured.",
                status_code=503,
                code="ai_not_configured",
            ) from exc
        except AgentFailed as exc:
            raise ApiError(
                "The daily reading agent failed.",
                status_code=502,
                code="agent_failed",
            ) from exc

        used_words = [word for word in output.target_words if word in output.passage]
        if not used_words:
            used_words = [word for word in target_words if word.lower() in output.passage.lower()]
        if not used_words:
            used_words = target_words

        reading.title = output.title
        reading.passage = output.passage
        reading.target_words_json = used_words
        reading.question = output.question
        reading.theme = theme
        session.add(reading)
        await session.flush()

    result = await _build_daily_out(
        session,
        reading,
        timed_speech,
        account_id=account_id,
    )
    await session.commit()
    return result


async def complete_daily_read(
    session: AsyncSession,
    *,
    account_id: str,
    duration_seconds: int | None,
) -> DailyCompleteOut:
    today: date = utcnow().date()
    reading = await session.scalar(
        select(DailyReading).where(
            DailyReading.account_id == account_id,
            DailyReading.reading_date == today,
        )
    )
    if reading is None or not reading.passage.strip():
        raise ApiError(
            "Daily reading is not ready.",
            status_code=404,
            code="daily_not_ready",
        )
    if reading.completed_at is None:
        reading.completed_at = utcnow()
        reading.completed_duration_seconds = duration_seconds
        session.add(reading)
        await session.commit()
    return DailyCompleteOut(
        date=reading.reading_date,
        completed=True,
        streak=await current_streak(session, account_id),
        word_count=len(reading.passage.split()),
        target_words=list(reading.target_words_json or []),
        duration_seconds=reading.completed_duration_seconds,
    )


_SENTENCE_END = re.compile(r'[.!?]+["\'”’)\]]*')


def split_sentences(text: str) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    cursor = 0
    for match in _SENTENCE_END.finditer(text):
        end = match.end()
        start = cursor
        while start < end and text[start].isspace():
            start += 1
        if start < end:
            spans.append((start, end))
        cursor = end
    if cursor < len(text):
        start = cursor
        while start < len(text) and text[start].isspace():
            start += 1
        if start < len(text):
            spans.append((start, len(text)))
    return spans


async def get_daily_translation(
    session: AsyncSession,
    *,
    account_id: str,
    agent: DailyTranslationAgent,
    reading_date: date | None = None,
) -> DailyTranslationOut:
    target_date = reading_date or utcnow().date()
    reading = await session.scalar(
        select(DailyReading).where(
            DailyReading.account_id == account_id,
            DailyReading.reading_date == target_date,
        )
    )
    if reading is None or not reading.passage.strip():
        raise ApiError(
            "Daily reading is not ready.",
            status_code=404,
            code="daily_not_ready",
        )

    native_language = await _native_language(session, account_id)
    if reading.translation_json and reading.translation_language == native_language:
        return DailyTranslationOut(
            language=native_language,
            lines=[DailyTranslationLineOut(**line) for line in reading.translation_json],
        )

    spans = split_sentences(reading.passage)
    if not spans:
        raise ApiError(
            "Daily reading has no sentences.",
            status_code=502,
            code="daily_translation_failed",
        )
    sentences = [reading.passage[start:end] for start, end in spans]
    try:
        translations = await agent.translate(
            sentences=sentences,
            native_language=native_language,
        )
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
    except TranslationFailed as exc:
        raise ApiError(
            "The daily translation agent failed.",
            status_code=502,
            code="daily_translation_failed",
        ) from exc
    if len(translations) != len(spans):
        raise ApiError(
            "The daily translation agent returned an invalid number of lines.",
            status_code=502,
            code="daily_translation_failed",
        )

    lines = [
        DailyTranslationLineOut(
            text=reading.passage[start:end],
            start_char=start,
            end_char=end,
            translation=translation.strip(),
        )
        for (start, end), translation in zip(spans, translations, strict=True)
    ]
    reading.translation_json = [line.model_dump() for line in lines]
    reading.translation_language = native_language
    session.add(reading)
    await session.commit()
    return DailyTranslationOut(language=native_language, lines=lines)
