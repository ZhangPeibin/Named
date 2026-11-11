from functools import lru_cache
from typing import Protocol

from pydantic import BaseModel, Field
from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from errors import ApiError


class WordLookupOutput(BaseModel):
    english_word: str = Field(min_length=1, max_length=200)


class WordLookupAgent(Protocol):
    async def resolve(self, *, text: str, native_language: str) -> str: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You resolve a selected word to the single English dictionary word a learner
should look up.

- If the input is Chinese or mixed language, translate its meaning to one
  English word.
- If the input is English, return its base dictionary form when appropriate.
- Return one word or a short established compound only.
- Do not explain, translate into Chinese, or add alternatives.
- Preserve names only when they are the thing being learned.
""".strip()


class PydanticAIWordLookupAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=WordLookupOutput,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def resolve(self, *, text: str, native_language: str) -> str:
        try:
            result = await self._agent.run(
                f"Learner native language: {native_language}\nSelected text: {text}"
            )
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output.english_word.strip()


@lru_cache
def get_word_lookup_agent() -> WordLookupAgent:
    settings = get_settings()
    try:
        return PydanticAIWordLookupAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
