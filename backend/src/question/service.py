from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from agents import AgentFailed
from errors import ApiError
from models import QuestionExchange, SoulProfile
from question.agent import QuestionAgent
from question.schemas import QuestionOut


def _out(row: QuestionExchange) -> QuestionOut:
    return QuestionOut(
        id=row.id,
        question=row.question,
        answer=row.answer,
        native_explanation=row.native_explanation,
        created_at=row.created_at,
    )


async def ask_question(
    session: AsyncSession,
    *,
    account_id: str,
    text: str,
    agent: QuestionAgent,
) -> QuestionOut:
    profile = await session.get(SoulProfile, account_id)
    native_language = profile.native_language if profile is not None else "en"
    try:
        result = await agent.ask(text=text, native_language=native_language)
    except AgentFailed as exc:
        raise ApiError(
            "The question agent failed.",
            status_code=502,
            code="question_agent_failed",
        ) from exc
    row = QuestionExchange(
        account_id=account_id,
        question=text,
        answer=result.answer,
        native_explanation=result.native_explanation,
    )
    session.add(row)
    await session.commit()
    await session.refresh(row)
    return _out(row)


async def list_questions(
    session: AsyncSession,
    *,
    account_id: str,
    limit: int = 30,
) -> list[QuestionOut]:
    rows = await session.scalars(
        select(QuestionExchange)
        .where(QuestionExchange.account_id == account_id)
        .order_by(QuestionExchange.created_at.desc())
        .limit(limit)
    )
    return [_out(row) for row in rows]
