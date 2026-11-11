import logging
from datetime import datetime, timedelta

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from config import Settings
from experience.agent import AgentFailed, ExperienceAgent
from experience.schemas import ExperienceCandidate, ExperienceExtraction
from models import (
    Conversation,
    ConversationMessage,
    Discovery,
    Experience,
    ExperienceJob,
    ExperienceSource,
    MessageAnnotation,
    MessageCorrection,
    SoulProfile,
    Word,
)

logger = logging.getLogger(__name__)

LIFE = "life"
LEARNING = "learning"


def _clean(value: str | None) -> str | None:
    if value is None:
        return None
    text = " ".join(value.split()).strip()
    return text or None


def _focus_title(discovery: Discovery | None) -> str:
    if discovery is None:
        return "Moment"
    if discovery.scene_payload_json:
        natural = discovery.scene_payload_json.get("natural_english")
        if isinstance(natural, str) and natural.strip():
            return natural.strip()
    return (discovery.input_text or "Moment").strip()


async def _focus_context(
    session: AsyncSession,
    account_id: str,
    conversation: Conversation,
) -> str:
    if conversation.focus_type == "word":
        word = await session.get(Word, conversation.focus_id)
        return f"Word: {word.label_en if word is not None else conversation.focus_id}"
    if conversation.focus_type == "scene":
        discovery = await session.get(Discovery, conversation.focus_id)
        if discovery is not None and discovery.account_id == account_id:
            return f"Scene: {_focus_title(discovery)}"
    return f"{conversation.focus_type}: {conversation.focus_id}"


async def enqueue_experience_job(
    session: AsyncSession,
    account_id: str,
    conversation_id: str,
    settings: Settings,
    *,
    now: datetime | None = None,
) -> ExperienceJob:
    current_time = now or utcnow()
    job = await session.scalar(
        select(ExperienceJob).where(ExperienceJob.conversation_id == conversation_id)
    )
    available_at = current_time + timedelta(seconds=settings.experience_debounce_seconds)
    if job is None:
        job = ExperienceJob(
            account_id=account_id,
            conversation_id=conversation_id,
            status="pending",
            attempts=0,
            available_at=available_at,
        )
        session.add(job)
    else:
        job.status = "pending"
        job.attempts = 0
        job.available_at = available_at
        job.last_error_code = None
    await session.flush()
    return job


def _supported_terms(candidate: ExperienceCandidate, evidence: str) -> list[str]:
    normalized = evidence.lower()
    terms: list[str] = []
    for raw in candidate.related_terms:
        term = _clean(raw)
        if term is None:
            continue
        if term.lower() not in normalized:
            continue
        if term not in terms:
            terms.append(term[:64])
    return terms


def _valid_candidate(
    candidate: ExperienceCandidate | None,
    *,
    messages: list[ConversationMessage],
    settings: Settings,
    kind: str,
) -> bool:
    if candidate is None:
        return False
    if candidate.confidence < settings.experience_confidence_threshold:
        return False
    if not _clean(candidate.summary):
        return False
    by_sequence = {message.sequence: message for message in messages}
    evidence = [by_sequence.get(sequence) for sequence in candidate.evidence_sequences]
    if any(message is None for message in evidence):
        return False
    if not evidence:
        return False
    if kind == LIFE and any(message.role != "user" for message in evidence):
        return False
    return True


async def _upsert_experience(
    session: AsyncSession,
    conversation: Conversation,
    kind: str,
    candidate: ExperienceCandidate | None,
    *,
    messages: list[ConversationMessage],
    corrections: list[str],
    annotations: list[str],
    settings: Settings,
) -> Experience | None:
    if not _valid_candidate(candidate, messages=messages, settings=settings, kind=kind):
        return None
    assert candidate is not None
    summary = _clean(candidate.summary)
    if summary is None:
        return None

    experience = await session.scalar(
        select(Experience).where(
            Experience.conversation_id == conversation.id,
            Experience.kind == kind,
        )
    )
    if experience is None:
        experience = Experience(
            account_id=conversation.account_id,
            conversation_id=conversation.id,
            kind=kind,
            summary=summary,
            detail=_clean(candidate.detail),
            confidence=candidate.confidence,
        )
        session.add(experience)
    else:
        experience.summary = summary
        experience.detail = _clean(candidate.detail)
        experience.confidence = candidate.confidence
        experience.deleted_at = None
    await session.flush()

    await session.execute(
        delete(ExperienceSource).where(ExperienceSource.experience_id == experience.id)
    )
    session.add(
        ExperienceSource(
            experience_id=experience.id,
            source_type="conversation",
            source_id=conversation.id,
        )
    )
    by_sequence = {message.sequence: message for message in messages}
    for sequence in dict.fromkeys(candidate.evidence_sequences):
        message = by_sequence[sequence]
        session.add(
            ExperienceSource(
                experience_id=experience.id,
                source_type="message",
                source_id=message.id,
                quote=message.text,
            )
        )
    if conversation.focus_type in {"word", "scene"}:
        session.add(
            ExperienceSource(
                experience_id=experience.id,
                source_type=conversation.focus_type,
                source_id=conversation.focus_id,
            )
        )
    evidence_text = "\n".join(
        [
            *(message.text for message in messages),
            *corrections,
            *annotations,
        ]
    )
    for term in _supported_terms(candidate, evidence_text):
        session.add(
            ExperienceSource(
                experience_id=experience.id,
                source_type="expression",
                source_id=term,
                quote=term,
            )
        )
    await session.flush()
    return experience


async def _process_job(
    session: AsyncSession,
    job: ExperienceJob,
    agent: ExperienceAgent,
    settings: Settings,
) -> None:
    conversation = await session.get(Conversation, job.conversation_id)
    if conversation is None or conversation.account_id != job.account_id:
        return

    messages = list(
        await session.scalars(
            select(ConversationMessage)
            .where(ConversationMessage.conversation_id == conversation.id)
            .order_by(ConversationMessage.sequence)
        )
    )
    if not messages:
        return
    corrections = list(
        await session.scalars(
            select(MessageCorrection)
            .join(
                ConversationMessage,
                ConversationMessage.id == MessageCorrection.message_id,
            )
            .where(ConversationMessage.conversation_id == conversation.id)
            .order_by(MessageCorrection.created_at)
        )
    )
    annotations = list(
        await session.scalars(
            select(MessageAnnotation)
            .join(
                ConversationMessage,
                ConversationMessage.id == MessageAnnotation.message_id,
            )
            .where(ConversationMessage.conversation_id == conversation.id)
            .order_by(MessageAnnotation.created_at)
        )
    )
    profile = await session.get(SoulProfile, conversation.account_id)
    native_language = profile.native_language if profile is not None else "en"
    focus_context = await _focus_context(session, conversation.account_id, conversation)

    extraction: ExperienceExtraction = await agent.extract(
        native_language=native_language,
        focus_context=focus_context,
        messages=[
            {"sequence": str(message.sequence), "role": message.role, "text": message.text}
            for message in messages
        ],
        corrections=[
            f"{correction.original} -> {correction.suggestion}; {correction.note}"
            for correction in corrections
        ],
        annotations=[f"{annotation.text}: {annotation.meaning_zh}" for annotation in annotations],
    )
    await _upsert_experience(
        session,
        conversation,
        LIFE,
        extraction.life,
        messages=messages,
        corrections=[correction.note for correction in corrections],
        annotations=[annotation.meaning_zh for annotation in annotations],
        settings=settings,
    )
    await _upsert_experience(
        session,
        conversation,
        LEARNING,
        extraction.learning,
        messages=messages,
        corrections=[correction.note for correction in corrections],
        annotations=[annotation.meaning_zh for annotation in annotations],
        settings=settings,
    )


async def process_due_experience_jobs(
    session: AsyncSession,
    agent: ExperienceAgent,
    settings: Settings,
    *,
    now: datetime | None = None,
    limit: int = 10,
) -> int:
    current_time = now or utcnow()
    jobs = list(
        await session.scalars(
            select(ExperienceJob)
            .where(
                ExperienceJob.status == "pending",
                ExperienceJob.available_at <= current_time,
            )
            .order_by(ExperienceJob.available_at)
            .limit(limit)
        )
    )
    processed = 0
    for job in jobs:
        job_id = job.id
        job.status = "running"
        await session.commit()
        try:
            await _process_job(session, job, agent, settings)
            await session.commit()
            job.status = "done"
            job.last_error_code = None
            await session.commit()
            processed += 1
        except AgentFailed:
            await session.rollback()
            await _mark_failed(session, job_id, settings, "agent_failed", current_time)
        except Exception:
            await session.rollback()
            await _mark_failed(session, job_id, settings, "processing_failed", current_time)
    return processed


async def _mark_failed(
    session: AsyncSession,
    job_id: str,
    settings: Settings,
    code: str,
    now: datetime,
) -> None:
    job = await session.get(ExperienceJob, job_id)
    if job is None:
        return
    job.attempts += 1
    job.last_error_code = code
    if job.attempts >= settings.experience_max_attempts:
        job.status = "failed"
    else:
        job.status = "pending"
        job.available_at = now + timedelta(seconds=min(60, 5 * job.attempts))
    await session.commit()
    logger.warning("Experience extraction failed: %s", code)
