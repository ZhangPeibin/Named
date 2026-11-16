from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from auth.router import CurrentAuthDep, SessionDep
from question.agent import QuestionAgent, get_question_agent
from question.schemas import (
    QuestionAskIn,
    QuestionFollowUpIn,
    QuestionThreadListOut,
    QuestionThreadOut,
)
from question.service import (
    ask_question,
    delete_thread,
    follow_up,
    get_thread,
    list_threads,
)
from ratelimit import TalkRateLimitDep

router = APIRouter(prefix="/questions", tags=["questions"])
QuestionAgentDep = Annotated[QuestionAgent, Depends(get_question_agent)]


@router.post("", response_model=QuestionThreadOut, status_code=status.HTTP_201_CREATED)
async def create_question(
    payload: QuestionAskIn,
    current: CurrentAuthDep,
    session: SessionDep,
    agent: QuestionAgentDep,
    _: TalkRateLimitDep,
) -> QuestionThreadOut:
    return await ask_question(
        session,
        account_id=current.account.id,
        text=payload.text.strip(),
        context=payload.context,
        agent=agent,
    )


@router.get("", response_model=QuestionThreadListOut)
async def read_questions(
    current: CurrentAuthDep,
    session: SessionDep,
    limit: Annotated[int, Query(ge=1, le=50)] = 30,
) -> QuestionThreadListOut:
    return QuestionThreadListOut(
        items=await list_threads(
            session,
            account_id=current.account.id,
            limit=limit,
        )
    )


@router.get("/{thread_id}", response_model=QuestionThreadOut)
async def read_question(
    thread_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> QuestionThreadOut:
    return await get_thread(
        session,
        account_id=current.account.id,
        thread_id=thread_id,
    )


@router.post("/{thread_id}/messages", response_model=QuestionThreadOut)
async def create_follow_up(
    thread_id: str,
    payload: QuestionFollowUpIn,
    current: CurrentAuthDep,
    session: SessionDep,
    agent: QuestionAgentDep,
    _: TalkRateLimitDep,
) -> QuestionThreadOut:
    return await follow_up(
        session,
        account_id=current.account.id,
        thread_id=thread_id,
        text=payload.text.strip(),
        agent=agent,
    )


@router.delete("/{thread_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_question(
    thread_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> None:
    await delete_thread(
        session,
        account_id=current.account.id,
        thread_id=thread_id,
    )
