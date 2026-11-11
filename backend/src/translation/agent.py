from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from errors import ApiError
from translation.schemas import TranslationAgentOutput


class TranslationAgent(Protocol):
    async def translate(self, *, text: str, target_language: str) -> str: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You translate short English or Chinese phrases for an English learner.

Rules:
- Translate exactly the meaning of the input.
- If target_language is "en", return natural English.
- If target_language is "zh", return natural Chinese.
- Preserve names, tone, and important terms.
- Do not add explanations, examples, alternatives, quotes, or Markdown.
- Return only the translated text.
""".strip()


class PydanticAITranslationAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=TranslationAgentOutput,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def translate(self, *, text: str, target_language: str) -> str:
        try:
            result = await self._agent.run(f"Target language: {target_language}\nText: {text}")
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output.translated_text.strip()


@lru_cache
def get_translation_agent() -> TranslationAgent:
    settings = get_settings()
    try:
        return PydanticAITranslationAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
