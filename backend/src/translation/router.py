import re
from typing import Annotated

from fastapi import APIRouter, Depends

from auth.router import CurrentAuthDep
from errors import ApiError
from ratelimit import TalkRateLimitDep
from translation.agent import AgentFailed, TranslationAgent, get_translation_agent
from translation.schemas import TranslationOut, TranslationRequest

router = APIRouter(prefix="/translate", tags=["translation"])

TranslationAgentDep = Annotated[TranslationAgent, Depends(get_translation_agent)]


def _target_language(text: str) -> tuple[str, str]:
    has_chinese = bool(re.search(r"[\u4e00-\u9fff]", text))
    if has_chinese:
        return "zh", "en"
    return "en", "zh"


@router.post("", response_model=TranslationOut)
async def translate(
    payload: TranslationRequest,
    current: CurrentAuthDep,
    agent: TranslationAgentDep,
    _: TalkRateLimitDep,
) -> TranslationOut:
    source_language, target_language = _target_language(payload.text)
    try:
        translated = await agent.translate(
            text=payload.text.strip(),
            target_language=target_language,
        )
    except AgentFailed as exc:
        raise ApiError(
            "The translation agent failed.",
            status_code=502,
            code="translation_failed",
        ) from exc
    if not translated:
        raise ApiError(
            "The translation was empty.",
            status_code=502,
            code="translation_failed",
        )
    return TranslationOut(
        source_language=source_language,
        target_language=target_language,
        translated_text=translated,
    )
