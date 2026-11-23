from fastapi import APIRouter

from auth.router import CurrentAuthDep, SessionDep
from progress.schemas import ProgressOut
from progress.service import get_progress

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("", response_model=ProgressOut)
async def read_progress(
    current: CurrentAuthDep,
    session: SessionDep,
) -> ProgressOut:
    words, conversations, readings, practices = await get_progress(session, current.account.id)
    return ProgressOut(
        words=words,
        conversations=conversations,
        readings=readings,
        practices=practices,
    )
