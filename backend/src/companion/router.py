from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from auth.router import CurrentAuthDep
from companion.presence import get_presence
from companion.presence_agent import PresenceAgent, get_presence_agent
from companion.schemas import CompanionOut, CompanionUpdate, NameSuggestionOut, PresenceOut
from companion.service import (
    assign_random_name,
    get_companion_out,
    suggest_name,
    update_companion,
)
from config import Settings, get_settings
from database import get_session

router = APIRouter(prefix="/companion", tags=["companion"])

SessionDep = Annotated[AsyncSession, Depends(get_session)]
SettingsDep = Annotated[Settings, Depends(get_settings)]
PresenceAgentDep = Annotated[PresenceAgent, Depends(get_presence_agent)]


@router.get("", response_model=CompanionOut)
async def read_companion(current: CurrentAuthDep, session: SessionDep) -> CompanionOut:
    return await get_companion_out(session, current.account.id)


@router.patch("", response_model=CompanionOut)
async def patch_companion(
    payload: CompanionUpdate,
    current: CurrentAuthDep,
    session: SessionDep,
) -> CompanionOut:
    return await update_companion(session, current.account.id, payload)


@router.get("/name-suggestion", response_model=NameSuggestionOut)
async def suggest_companion_name(
    current: CurrentAuthDep,
    session: SessionDep,
) -> NameSuggestionOut:
    return NameSuggestionOut(name=await suggest_name(session, current.account.id))


@router.get("/presence", response_model=PresenceOut)
async def read_presence(
    local_hour: Annotated[int, Query(ge=0, le=23)],
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    agent: PresenceAgentDep,
) -> PresenceOut:
    return await get_presence(
        session,
        current.account.id,
        local_hour,
        agent,
        settings,
    )


@router.post("/random-name", response_model=CompanionOut)
async def assign_companion_name(
    current: CurrentAuthDep,
    session: SessionDep,
) -> CompanionOut:
    return await assign_random_name(session, current.account.id)
