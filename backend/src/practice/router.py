from typing import Annotated

from fastapi import APIRouter, Depends

from auth.router import CurrentAuthDep, SessionDep
from practice.agent import PracticeAgent, get_practice_agent
from practice.schemas import (
    PracticeCompleteOut,
    PracticeReplyIn,
    PracticeReplyOut,
    PracticeWordOut,
)
from practice.service import complete_practice, get_next_practice, practice_reply
from tts.deps import WordAudioServiceDep

router = APIRouter(prefix="/practice", tags=["practice"])

PracticeAgentDep = Annotated[PracticeAgent, Depends(get_practice_agent)]


@router.get("/next", response_model=PracticeWordOut)
async def next_word(
    current: CurrentAuthDep,
    session: SessionDep,
    audio_service: WordAudioServiceDep,
) -> PracticeWordOut:
    return await get_next_practice(session, current.account.id, audio_service)


@router.post("/{word_id}/complete", response_model=PracticeCompleteOut)
async def complete(
    word_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> PracticeCompleteOut:
    return await complete_practice(session, current.account.id, word_id)


@router.post("/{word_id}/reply", response_model=PracticeReplyOut)
async def reply(
    word_id: str,
    payload: PracticeReplyIn,
    current: CurrentAuthDep,
    session: SessionDep,
    agent: PracticeAgentDep,
) -> PracticeReplyOut:
    return await practice_reply(
        session,
        current.account.id,
        word_id,
        payload,
        agent,
    )
