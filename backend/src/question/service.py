from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from agents import AgentFailed
from clock import utcnow
from companion.context import format_companion_context
from companion.service import get_companion
from errors import ApiError
from models import QuestionMessage, QuestionThread, SoulProfile
from question.agent import QuestionAgent
from question.schemas import (
    QuestionContextIn,
    QuestionMessageOut,
    QuestionThreadOut,
    QuestionThreadSummaryOut,
)


def _message_out(row: QuestionMessage) -> QuestionMessageOut:
    return QuestionMessageOut(
        id=row.id,
        role=row.role,
        text=row.text,
        example=row.example,
        native_explanation=row.native_explanation,
        confidence=row.confidence,
        follow_up_suggestions=list(row.suggestions_json or []),
        feedback=row.feedback,
        created_at=row.created_at,
    )


def _thread_out(thread: QuestionThread, messages: list[QuestionMessage]) -> QuestionThreadOut:
    return QuestionThreadOut(
        id=thread.id,
        title=thread.title,
        context_type=thread.context_type,
        context_ref=thread.context_ref,
        context_quote=thread.context_quote,
        messages=[_message_out(message) for message in messages],
        created_at=thread.created_at,
        updated_at=thread.updated_at,
    )


def _summary_out(thread: QuestionThread, last_text: str) -> QuestionThreadSummaryOut:
    return QuestionThreadSummaryOut(
        id=thread.id,
        title=thread.title,
        context_type=thread.context_type,
        context_quote=thread.context_quote,
        last_text=last_text,
        updated_at=thread.updated_at,
    )


async def _thread_or_404(
    session: AsyncSession,
    *,
    account_id: str,
    thread_id: str,
) -> QuestionThread:
    thread = await session.scalar(
        select(QuestionThread).where(
            QuestionThread.id == thread_id,
            QuestionThread.account_id == account_id,
            QuestionThread.deleted_at.is_(None),
        )
    )
    if thread is None:
        raise ApiError(
            "Question thread not found.",
            status_code=404,
            code="question_thread_not_found",
        )
    return thread


async def _messages(
    session: AsyncSession,
    thread_id: str,
) -> list[QuestionMessage]:
    return list(
        await session.scalars(
            select(QuestionMessage)
            .where(QuestionMessage.thread_id == thread_id)
            .order_by(QuestionMessage.sequence, QuestionMessage.created_at, QuestionMessage.id)
        )
    )


def _history(messages: list[QuestionMessage]) -> list[dict[str, str]]:
    return [{"role": message.role, "text": message.text} for message in messages[-10:]]


async def _native_language(session: AsyncSession, account_id: str) -> str:
    profile = await session.get(SoulProfile, account_id)
    return profile.native_language if profile is not None else "en"


async def _companion_context(session: AsyncSession, account_id: str) -> str:
    return format_companion_context(await get_companion(session, account_id))


async def _run_agent(
    agent: QuestionAgent,
    *,
    text: str,
    native_language: str,
    companion_context: str,
    context_type: str | None,
    context_quote: str | None,
    history: list[dict[str, str]],
):
    try:
        return await agent.ask(
            text=text,
            native_language=native_language,
            companion_context=companion_context,
            context_type=context_type,
            context_quote=context_quote,
            history=history,
        )
    except AgentFailed as exc:
        raise ApiError(
            "The question agent failed.",
            status_code=502,
            code="question_agent_failed",
        ) from exc


async def ask_question(
    session: AsyncSession,
    *,
    account_id: str,
    text: str,
    context: QuestionContextIn | None,
    agent: QuestionAgent,
) -> QuestionThreadOut:
    native_language = await _native_language(session, account_id)
    context_type = context.type if context is not None else None
    context_ref = context.ref if context is not None else None
    context_quote = context.quote if context is not None else None
    if context_type == "none":
        context_type = None

    result = await _run_agent(
        agent,
        text=text,
        native_language=native_language,
        companion_context=await _companion_context(session, account_id),
        context_type=context_type,
        context_quote=context_quote,
        history=[],
    )
    thread = QuestionThread(
        account_id=account_id,
        title=text.strip()[:200],
        context_type=context_type,
        context_ref=context_ref,
        context_quote=context_quote,
    )
    session.add(thread)
    await session.flush()
    session.add_all(
        [
            QuestionMessage(
                thread_id=thread.id,
                role="user",
                sequence=1,
                text=text,
            ),
            QuestionMessage(
                thread_id=thread.id,
                role="assistant",
                sequence=2,
                text=result.answer,
                example=result.example,
                native_explanation=result.native_explanation,
                confidence=result.confidence,
                suggestions_json=result.follow_up_suggestions,
            ),
        ]
    )
    await session.commit()
    await session.refresh(thread)
    return _thread_out(thread, await _messages(session, thread.id))


async def follow_up(
    session: AsyncSession,
    *,
    account_id: str,
    thread_id: str,
    text: str,
    agent: QuestionAgent,
) -> QuestionThreadOut:
    thread = await _thread_or_404(
        session,
        account_id=account_id,
        thread_id=thread_id,
    )
    messages = await _messages(session, thread.id)
    native_language = await _native_language(session, account_id)
    result = await _run_agent(
        agent,
        text=text,
        native_language=native_language,
        companion_context=await _companion_context(session, account_id),
        context_type=thread.context_type,
        context_quote=thread.context_quote,
        history=_history(messages),
    )
    next_sequence = max((message.sequence for message in messages), default=0) + 1
    session.add_all(
        [
            QuestionMessage(
                thread_id=thread.id,
                role="user",
                sequence=next_sequence,
                text=text,
            ),
            QuestionMessage(
                thread_id=thread.id,
                role="assistant",
                sequence=next_sequence + 1,
                text=result.answer,
                example=result.example,
                native_explanation=result.native_explanation,
                confidence=result.confidence,
                suggestions_json=result.follow_up_suggestions,
            ),
        ]
    )
    thread.updated_at = utcnow()
    session.add(thread)
    await session.commit()
    await session.refresh(thread)
    return _thread_out(thread, await _messages(session, thread.id))


async def get_thread(
    session: AsyncSession,
    *,
    account_id: str,
    thread_id: str,
) -> QuestionThreadOut:
    thread = await _thread_or_404(
        session,
        account_id=account_id,
        thread_id=thread_id,
    )
    return _thread_out(thread, await _messages(session, thread.id))


async def list_threads(
    session: AsyncSession,
    *,
    account_id: str,
    limit: int = 30,
) -> list[QuestionThreadSummaryOut]:
    threads = list(
        await session.scalars(
            select(QuestionThread)
            .where(
                QuestionThread.account_id == account_id,
                QuestionThread.deleted_at.is_(None),
            )
            .order_by(QuestionThread.updated_at.desc())
            .limit(limit)
        )
    )
    if not threads:
        return []
    thread_ids = [thread.id for thread in threads]
    messages = list(
        await session.scalars(
            select(QuestionMessage)
            .where(QuestionMessage.thread_id.in_(thread_ids))
            .order_by(QuestionMessage.sequence.desc())
        )
    )
    last_by_thread: dict[str, str] = {}
    for message in messages:
        if message.role == "assistant":
            last_by_thread.setdefault(message.thread_id, message.text)
    return [_summary_out(thread, last_by_thread.get(thread.id, "")) for thread in threads]


async def delete_thread(
    session: AsyncSession,
    *,
    account_id: str,
    thread_id: str,
) -> None:
    thread = await _thread_or_404(
        session,
        account_id=account_id,
        thread_id=thread_id,
    )
    thread.deleted_at = utcnow()
    session.add(thread)
    await session.commit()


async def set_feedback(
    session: AsyncSession,
    *,
    account_id: str,
    thread_id: str,
    message_id: str,
    feedback: str,
) -> QuestionMessageOut:
    thread = await _thread_or_404(
        session,
        account_id=account_id,
        thread_id=thread_id,
    )
    message = await session.scalar(
        select(QuestionMessage).where(
            QuestionMessage.id == message_id,
            QuestionMessage.thread_id == thread.id,
        )
    )
    if message is None:
        raise ApiError(
            "Question message not found.",
            status_code=404,
            code="question_message_not_found",
        )
    if message.role != "assistant":
        raise ApiError(
            "Only assistant answers can receive feedback.",
            status_code=400,
            code="question_feedback_invalid",
        )
    message.feedback = feedback
    session.add(message)
    await session.commit()
    await session.refresh(message)
    return _message_out(message)
