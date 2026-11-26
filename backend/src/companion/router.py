from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from auth.router import CurrentAuthDep
from companion.schemas import CompanionOut, CompanionUpdate, NameSuggestionOut
from companion.service import (
    assign_random_name,
    get_companion_out,
    suggest_name,
    update_companion,
)
from database import get_session

router = APIRouter(prefix="/companion", tags=["companion"])

SessionDep = Annotated[AsyncSession, Depends(get_session)]


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


@router.post("/random-name", response_model=CompanionOut)
async def assign_companion_name(
    current: CurrentAuthDep,
    session: SessionDep,
) -> CompanionOut:
    return await assign_random_name(session, current.account.id)
