from datetime import timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ai import AINotConfigured
from clock import utcnow
from config import Settings
from discovery.agent import AgentFailed, DiscoveryAgent
from discovery.schemas import (
    CandidateOut,
    DiscoveryAgentOutput,
    DiscoveryOut,
    FocusRequest,
    ScenePayload,
    WordListItem,
    WordOut,
    WordPayload,
    WordProgressOut,
    WordsResponse,
    WordsStats,
)
from errors import ApiError
from media import MediaStore
from models import (
    Conversation,
    Discovery,
    DiscoveryCandidate,
    SoulProfile,
    Word,
    WordContent,
    WordProgress,
)
from tts.schemas import SpeechAudioOut
from tts.service import SpeechAudioService, WordAudioService


def normalize_label(label: str) -> str:
    return " ".join(label.strip().split())


def canonical_key(label: str) -> str:
    return normalize_label(label).lower()


async def _native_language(session: AsyncSession, account_id: str) -> str:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        raise ApiError("Soul not found.", status_code=404, code="soul_not_found")
    return profile.native_language


async def _get_discovery(session: AsyncSession, account_id: str, discovery_id: str) -> Discovery:
    discovery = await session.scalar(
        select(Discovery).where(
            Discovery.id == discovery_id,
            Discovery.account_id == account_id,
            Discovery.deleted_at.is_(None),
        )
    )
    if discovery is None:
        raise ApiError("Discovery not found.", status_code=404, code="discovery_not_found")
    return discovery


async def _get_candidates(session: AsyncSession, discovery_id: str) -> list[DiscoveryCandidate]:
    rows = await session.scalars(
        select(DiscoveryCandidate)
        .where(DiscoveryCandidate.discovery_id == discovery_id)
        .order_by(DiscoveryCandidate.created_at)
    )
    return list(rows)


async def _latest_word_content(
    session: AsyncSession,
    word_id: str,
    native_language: str,
    settings: Settings,
) -> WordContent | None:
    return await session.scalar(
        select(WordContent)
        .where(
            WordContent.word_id == word_id,
            WordContent.native_language == native_language,
            WordContent.model == settings.ai_model,
            WordContent.prompt_version == settings.ai_prompt_version,
        )
        .order_by(WordContent.created_at.desc())
        .limit(1)
    )


async def _get_or_create_word_content(
    session: AsyncSession,
    label: str,
    payload: WordPayload | None,
    native_language: str,
    settings: Settings,
    agent: DiscoveryAgent,
    context: str | None,
    confirmed_label: str | None = None,
) -> tuple[Word, WordPayload]:
    normalized = normalize_label(label)
    key = canonical_key(normalized)

    word = await session.scalar(select(Word).where(Word.canonical_key == key))
    if word is None:
        word = Word(canonical_key=key, label_en=normalized)
        session.add(word)
        await session.flush()

    cached = await _latest_word_content(session, word.id, native_language, settings)
    if cached is not None:
        return word, WordPayload.model_validate(cached.payload_json)

    if payload is None:
        try:
            output = await agent.analyze(
                normalized,
                native_language,
                context=context,
                confirmed_label=confirmed_label or normalized,
            )
        except AINotConfigured as exc:
            raise ApiError(
                "AI provider is not configured.",
                status_code=503,
                code="ai_not_configured",
            ) from exc
        except AgentFailed as exc:
            raise ApiError(
                "The discovery agent failed.",
                status_code=502,
                code="agent_failed",
            ) from exc
        if output.word is None:
            raise ApiError(
                "The discovery agent returned no word content.",
                status_code=502,
                code="agent_invalid_output",
            )
        payload = output.word

    if confirmed_label is not None:
        payload = payload.model_copy(update={"spelling": normalize_label(confirmed_label)})

    content = WordContent(
        word_id=word.id,
        native_language=native_language,
        payload_json=payload.model_dump(mode="json"),
        source="ai",
        model=settings.ai_model,
        prompt_version=settings.ai_prompt_version,
    )
    session.add(content)
    await session.flush()
    return word, payload


async def _discovery_out(
    session: AsyncSession,
    discovery: Discovery,
    settings: Settings,
    audio_service: WordAudioService,
) -> DiscoveryOut:
    candidates = await _get_candidates(session, discovery.id)
    word: WordPayload | None = None
    scene: ScenePayload | None = None
    audio = None
    scene_audio = None
    if discovery.word_id is not None:
        native_language = await _native_language(session, discovery.account_id)
        content = await _latest_word_content(session, discovery.word_id, native_language, settings)
        if content is not None:
            word = WordPayload.model_validate(content.payload_json)

        word_row = await session.get(Word, discovery.word_id)
        if word_row is not None:
            audio = await audio_service.for_word(session, word_row)

    if discovery.scene_payload_json is not None:
        scene = ScenePayload.model_validate(discovery.scene_payload_json)
    if discovery.scene_audio_key:
        scene_audio = SpeechAudioOut(
            url=f"{settings.media_url_prefix.rstrip('/')}/{discovery.scene_audio_key}",
            status="ready",
        )

    status = discovery.status
    if status not in {"needs_confirmation", "ready"}:
        status = "needs_confirmation"

    return DiscoveryOut(
        id=discovery.id,
        input_type=discovery.input_type,
        input_text=discovery.input_text,
        context=discovery.context,
        image_url=(
            f"{settings.image_url_prefix.rstrip('/')}/{discovery.image_key}"
            if discovery.image_key
            else None
        ),
        input_language=discovery.input_language,
        status=status,
        focus_kind=discovery.focus_kind,
        word_id=discovery.word_id,
        candidates=[CandidateOut.model_validate(row) for row in candidates],
        word=word,
        scene=scene,
        audio=audio,
        scene_audio=scene_audio,
        needs_confirmation=status == "needs_confirmation",
        warnings=discovery.warnings_json or [],
    )


async def create_discovery(
    session: AsyncSession,
    account_id: str,
    text: str | None,
    context: str | None,
    image: bytes | None,
    image_media_type: str | None,
    image_key: str | None,
    agent: DiscoveryAgent,
    settings: Settings,
    audio_service: WordAudioService,
    speech_service: SpeechAudioService,
) -> DiscoveryOut:
    normalized_text = (text or "").strip()
    if not normalized_text and image is None:
        raise ApiError("text or image is required.", code="input_required")

    native_language = await _native_language(session, account_id)

    try:
        output: DiscoveryAgentOutput = await agent.analyze(
            normalized_text,
            native_language,
            context=context,
            image=image,
            image_media_type=image_media_type,
        )
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
    except AgentFailed as exc:
        raise ApiError(
            "The discovery agent failed.",
            status_code=502,
            code="agent_failed",
        ) from exc

    scene_payload = output.scene if output.focus.kind == "scene" else None
    discovery = Discovery(
        account_id=account_id,
        input_type="image" if image is not None else "text",
        input_text=normalized_text or None,
        context=context,
        image_key=image_key,
        input_language=output.input_language,
        focus_kind=output.focus.kind,
        status="ready",
        warnings_json=output.warnings,
        scene_payload_json=(
            scene_payload.model_dump(mode="json") if scene_payload is not None else None
        ),
    )
    session.add(discovery)
    await session.flush()

    if output.focus.kind == "word":
        word, _ = await _get_or_create_word_content(
            session,
            output.focus.label_en,
            output.word,
            native_language,
            settings,
            agent,
            context,
            confirmed_label=output.focus.label_en,
        )
        discovery.word_id = word.id
    elif scene_payload is not None:
        _, scene_audio_key = await speech_service.synthesize(
            session,
            scene_payload.natural_english,
        )
        discovery.scene_audio_key = scene_audio_key

    await session.commit()
    return await _discovery_out(session, discovery, settings, audio_service)


async def focus_discovery(
    session: AsyncSession,
    account_id: str,
    discovery_id: str,
    payload: FocusRequest,
    agent: DiscoveryAgent,
    settings: Settings,
    audio_service: WordAudioService,
) -> DiscoveryOut:
    discovery = await _get_discovery(session, account_id, discovery_id)
    if discovery.status == "ready":
        return await _discovery_out(session, discovery, settings, audio_service)

    candidates = await _get_candidates(session, discovery.id)

    if payload.whole_scene:
        discovery.focus_kind = "scene"
        discovery.word_id = None
        discovery.status = "ready"
        for row in candidates:
            row.selected = False
        await session.commit()
        return await _discovery_out(session, discovery, settings, audio_service)

    selected: DiscoveryCandidate | None = None
    if payload.candidate_id is not None:
        selected = next((row for row in candidates if row.id == payload.candidate_id), None)
        if selected is None:
            raise ApiError(
                "Discovery candidate not found.",
                status_code=404,
                code="candidate_not_found",
            )
        label = selected.label_en
    else:
        label = normalize_label(payload.label_en or "")
        if not label:
            raise ApiError("label_en is required.", code="label_required")
        selected = next(
            (row for row in candidates if canonical_key(row.label_en) == canonical_key(label)),
            None,
        )
        if selected is None:
            selected = DiscoveryCandidate(
                discovery_id=discovery.id,
                label_en=label,
                label_zh=label,
                confidence=1.0,
                reason="Learner adjusted the English name.",
                provider="user",
            )
            session.add(selected)
            candidates.append(selected)
            await session.flush()

    native_language = await _native_language(session, account_id)
    word, _ = await _get_or_create_word_content(
        session,
        label,
        None,
        native_language,
        settings,
        agent,
        discovery.context,
        confirmed_label=label,
    )

    for row in candidates:
        row.selected = row.id == selected.id
    discovery.focus_kind = "word"
    discovery.word_id = word.id
    discovery.status = "ready"
    await session.commit()
    return await _discovery_out(session, discovery, settings, audio_service)


async def get_discovery(
    session: AsyncSession,
    account_id: str,
    discovery_id: str,
    settings: Settings,
    audio_service: WordAudioService,
) -> DiscoveryOut:
    discovery = await _get_discovery(session, account_id, discovery_id)
    return await _discovery_out(session, discovery, settings, audio_service)


async def get_word(
    session: AsyncSession,
    account_id: str,
    word_id: str,
    settings: Settings,
    audio_service: WordAudioService,
) -> WordOut:
    word = await session.get(Word, word_id)
    if word is None:
        raise ApiError("Word not found.", status_code=404, code="word_not_found")

    native_language = await _native_language(session, account_id)
    content = await _latest_word_content(session, word.id, native_language, settings)
    audio = await audio_service.for_word(session, word)
    return WordOut(
        id=word.id,
        label_en=word.label_en,
        content=WordPayload.model_validate(content.payload_json) if content else None,
        audio=audio,
    )


async def delete_discovery(
    session: AsyncSession,
    account_id: str,
    discovery_id: str,
    store: MediaStore,
) -> None:
    discovery = await _get_discovery(session, account_id, discovery_id)
    if discovery.image_key:
        await store.delete(discovery.image_key)
    discovery.deleted_at = utcnow()
    await session.commit()


def _week_start(now):
    return (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)


def _word_status(progress: WordProgress | None, now) -> str:
    if progress is not None and progress.self_known_at is not None:
        return "known"
    if (
        progress is not None
        and progress.last_reviewed_at is not None
        and progress.last_reviewed_at >= now - timedelta(days=7)
    ):
        return "growing"
    return "needs_review"


async def _owned_word(session: AsyncSession, account_id: str, word_id: str) -> Word:
    word = await session.get(Word, word_id)
    linked = await session.scalar(
        select(Discovery.id)
        .where(
            Discovery.account_id == account_id,
            Discovery.word_id == word_id,
            Discovery.deleted_at.is_(None),
        )
        .limit(1)
    )
    if word is None or linked is None:
        raise ApiError("Word not found.", status_code=404, code="word_not_found")
    return word


async def _get_or_create_progress(
    session: AsyncSession, account_id: str, word_id: str
) -> WordProgress:
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
    return progress


async def get_words(
    session: AsyncSession,
    account_id: str,
    settings: Settings,
    audio_service: WordAudioService,
) -> WordsResponse:
    native_language = await _native_language(session, account_id)
    now = utcnow()
    week_start = _week_start(now)

    rows = (
        await session.execute(
            select(
                Word,
                func.count(Discovery.id),
                func.min(Discovery.created_at),
                func.max(Discovery.created_at),
            )
            .join(Discovery, Discovery.word_id == Word.id)
            .where(
                Discovery.account_id == account_id,
                Discovery.deleted_at.is_(None),
                Discovery.status == "ready",
                Discovery.focus_kind == "word",
            )
            .group_by(Word.id)
            .order_by(func.max(Discovery.created_at).desc())
        )
    ).all()

    word_ids = [row[0].id for row in rows]
    content_by_word: dict[str, WordContent] = {}
    progress_by_word: dict[str, WordProgress] = {}
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

        progress_rows = await session.scalars(
            select(WordProgress).where(
                WordProgress.account_id == account_id,
                WordProgress.word_id.in_(word_ids),
            )
        )
        progress_by_word = {progress.word_id: progress for progress in progress_rows}

    used_in_talk = await session.scalar(
        select(func.count(func.distinct(Conversation.focus_id))).where(
            Conversation.account_id == account_id,
            Conversation.focus_type == "word",
            Conversation.started_at >= week_start,
        )
    )

    items: list[WordListItem] = []
    for word, discovery_count, first_seen_at, last_seen_at in rows:
        content = content_by_word.get(word.id)
        progress = progress_by_word.get(word.id)
        items.append(
            WordListItem(
                id=word.id,
                label_en=word.label_en,
                content=(
                    WordPayload.model_validate(content.payload_json)
                    if content is not None
                    else None
                ),
                audio=await audio_service.for_word(session, word),
                discovery_count=discovery_count,
                first_seen_at=first_seen_at,
                last_seen_at=last_seen_at,
                status=_word_status(progress, now),
                review_count=progress.review_count if progress is not None else 0,
                last_reviewed_at=(progress.last_reviewed_at if progress is not None else None),
            )
        )

    status_rank = {"needs_review": 0, "growing": 1, "known": 2}
    items.sort(key=lambda item: (status_rank[item.status], -item.last_seen_at.timestamp()))
    new_this_week = sum(1 for item in items if item.first_seen_at >= week_start)
    reviewed_this_week = sum(
        1
        for progress in progress_by_word.values()
        if progress.last_reviewed_at is not None and progress.last_reviewed_at >= week_start
    )

    return WordsResponse(
        stats=WordsStats(
            total=len(items),
            new_this_week=new_this_week,
            reviewed_this_week=reviewed_this_week,
            used_in_talk_this_week=used_in_talk or 0,
        ),
        words=items,
    )


async def set_word_known(
    session: AsyncSession,
    account_id: str,
    word_id: str,
    known: bool,
) -> WordProgressOut:
    await _owned_word(session, account_id, word_id)
    progress = await _get_or_create_progress(session, account_id, word_id)
    progress.self_known_at = utcnow() if known else None
    await session.commit()
    now = utcnow()
    return WordProgressOut(
        word_id=word_id,
        status=_word_status(progress, now),
        review_count=progress.review_count,
        last_reviewed_at=progress.last_reviewed_at,
    )


async def mark_word_reviewed(
    session: AsyncSession,
    account_id: str,
    word_id: str,
) -> WordProgressOut:
    await _owned_word(session, account_id, word_id)
    progress = await _get_or_create_progress(session, account_id, word_id)
    progress.review_count += 1
    progress.last_reviewed_at = utcnow()
    await session.commit()
    now = utcnow()
    return WordProgressOut(
        word_id=word_id,
        status=_word_status(progress, now),
        review_count=progress.review_count,
        last_reviewed_at=progress.last_reviewed_at,
    )
