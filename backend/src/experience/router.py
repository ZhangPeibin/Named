from typing import Annotated

from fastapi import APIRouter, Query

from auth.router import CurrentAuthDep, SessionDep
from experience.history import get_experience, list_experiences
from experience.schemas import ExperienceDetailOut, ExperienceListOut

history_router = APIRouter(prefix="/history", tags=["history"])
experience_router = APIRouter(prefix="/experiences", tags=["history"])


@history_router.get("", response_model=ExperienceListOut)
async def history(
    current: CurrentAuthDep,
    session: SessionDep,
    before: str | None = None,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
) -> ExperienceListOut:
    return await list_experiences(
        session,
        current.account.id,
        before=before,
        limit=limit,
    )


@experience_router.get("/{experience_id}", response_model=ExperienceDetailOut)
async def read_experience(
    experience_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> ExperienceDetailOut:
    return await get_experience(session, current.account.id, experience_id)
