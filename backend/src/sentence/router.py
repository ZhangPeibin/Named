from typing import Annotated

from fastapi import APIRouter, Depends

from auth.router import CurrentAuthDep, SessionDep, SettingsDep
from errors import ApiError
from models import SoulProfile
from ratelimit import TalkRateLimitDep
from sentence.agent import AgentFailed, SentenceAgent, get_sentence_agent
from sentence.schemas import SentenceLookupRequest, SentenceOut

router = APIRouter(prefix="/sentences", tags=["sentences"])

SentenceAgentDep = Annotated[SentenceAgent, Depends(get_sentence_agent)]


@router.post("/lookup", response_model=SentenceOut)
async def lookup_sentence(
    payload: SentenceLookupRequest,
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    agent: SentenceAgentDep,
    _: TalkRateLimitDep,
) -> SentenceOut:
    profile = await session.get(SoulProfile, current.account.id)
    native_language = profile.native_language if profile is not None else "en"
    text = payload.text.strip()
    if not text:
        raise ApiError("Sentence is empty.", code="sentence_empty")
    try:
        result = await agent.explain(text=text, native_language=native_language)
    except AgentFailed as exc:
        raise ApiError(
            "The sentence agent failed.",
            status_code=502,
            code="sentence_agent_failed",
        ) from exc
    return SentenceOut(
        original=text,
        natural_english=result.natural_english,
        explanation_native=result.explanation_native,
        grammar_notes=result.grammar_notes,
        chunks=result.chunks,
        key_words=result.key_words,
    )
