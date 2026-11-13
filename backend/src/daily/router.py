from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from auth.router import CurrentAuthDep, SessionDep, SettingsDep
from daily.agent import DailyReadAgent, get_daily_read_agent
from daily.schemas import (
    DailyCompleteIn,
    DailyCompleteOut,
    DailyReadOut,
    DailyTranslationOut,
)
from daily.service import (
    complete_daily_read,
    get_daily_read,
    get_daily_translation,
)
from daily.translation_agent import (
    DailyTranslationAgent,
    get_daily_translation_agent,
)
from errors import ApiError
from ratelimit import TalkRateLimitDep
from tts.deps import TimedSpeechServiceDep

router = APIRouter(prefix="/daily", tags=["daily"])


def _reading_date(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise ApiError(
            "Invalid daily reading date.",
            status_code=400,
            code="invalid_date",
        ) from exc


DailyReadAgentDep = Annotated[DailyReadAgent, Depends(get_daily_read_agent)]
DailyTranslationAgentDep = Annotated[DailyTranslationAgent, Depends(get_daily_translation_agent)]


@router.get("/read", response_model=DailyReadOut)
async def read_daily(
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    agent: DailyReadAgentDep,
    timed_speech: TimedSpeechServiceDep,
    _: TalkRateLimitDep,
    reading_date: Annotated[str | None, Query(alias="date")] = None,
) -> DailyReadOut:
    return await get_daily_read(
        session,
        account_id=current.account.id,
        agent=agent,
        timed_speech=timed_speech,
        settings=settings,
        reading_date=_reading_date(reading_date),
    )


@router.get("/read/translation", response_model=DailyTranslationOut)
async def read_daily_translation(
    current: CurrentAuthDep,
    session: SessionDep,
    agent: DailyTranslationAgentDep,
    _: TalkRateLimitDep,
    reading_date: Annotated[str | None, Query(alias="date")] = None,
) -> DailyTranslationOut:
    return await get_daily_translation(
        session,
        account_id=current.account.id,
        agent=agent,
        reading_date=_reading_date(reading_date),
    )


@router.post("/read/complete", response_model=DailyCompleteOut)
async def complete_daily_reading(
    payload: DailyCompleteIn,
    current: CurrentAuthDep,
    session: SessionDep,
) -> DailyCompleteOut:
    return await complete_daily_read(
        session,
        account_id=current.account.id,
        duration_seconds=payload.duration_seconds,
    )
