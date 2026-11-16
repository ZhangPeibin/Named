from typing import Annotated

from fastapi import APIRouter, Depends, Query

from auth.router import CurrentAuthDep, SessionDep
from question.agent import QuestionAgent, get_question_agent
from question.schemas import QuestionAskIn, QuestionListOut, QuestionOut
from question.service import ask_question, list_questions
from ratelimit import TalkRateLimitDep

router = APIRouter(prefix="/questions", tags=["questions"])
QuestionAgentDep = Annotated[QuestionAgent, Depends(get_question_agent)]


@router.post("", response_model=QuestionOut)
async def create_question(
    payload: QuestionAskIn,
    current: CurrentAuthDep,
    session: SessionDep,
    agent: QuestionAgentDep,
    _: TalkRateLimitDep,
) -> QuestionOut:
    return await ask_question(
        session,
        account_id=current.account.id,
        text=payload.text.strip(),
        agent=agent,
    )


@router.get("", response_model=QuestionListOut)
async def read_questions(
    current: CurrentAuthDep,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=50)] = 30,
) -> QuestionListOut:
    return QuestionListOut(
        items=await list_questions(
            session,
            account_id=current.account.id,
            limit=limit,
        )
    )
