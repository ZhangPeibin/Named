from typing import Annotated, Literal

from fastapi import APIRouter, Query

from auth.router import CurrentAuthDep, SessionDep
from timeline.schemas import TimelineResponse
from timeline.service import get_timeline
from tts.deps import WordAudioServiceDep

router = APIRouter(prefix="/timeline", tags=["timeline"])


@router.get("", response_model=TimelineResponse)
async def read_timeline(
    current: CurrentAuthDep,
    session: SessionDep,
    audio_service: WordAudioServiceDep,
    limit: Annotated[int, Query(ge=1, le=50)] = 30,
    before: str | None = None,
    item_type: Annotated[
        Literal["all", "word", "talk"],
        Query(alias="type"),
    ] = "all",
) -> TimelineResponse:
    return await get_timeline(
        session,
        current.account.id,
        audio_service,
        limit=limit,
        before=before,
        item_type=item_type,
    )
