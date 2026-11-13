from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from daily.schemas import DailyTranslationAgentOutput
from errors import ApiError


class DailyTranslationAgent(Protocol):
    async def translate(
        self,
        *,
        sentences: list[str],
        native_language: str,
    ) -> list[str]: ...


class TranslationFailed(Exception):
    pass


SYSTEM_PROMPT = """
You translate a short English reading into the learner's native language.

Rules:
- Translate every numbered sentence exactly once, in the same order.
- Keep the number of translations identical to the number of input sentences.
- Do not merge, split, skip, or add sentences.
- Preserve meaning, tone, names, and small details.
- Use natural, simple language for an English learner.
- Return plain text only, with no Markdown, numbering, or explanations.
""".strip()


class PydanticAIDailyTranslationAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=DailyTranslationAgentOutput,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def translate(
        self,
        *,
        sentences: list[str],
        native_language: str,
    ) -> list[str]:
        numbered = "\n".join(f"{index + 1}. {sentence}" for index, sentence in enumerate(sentences))
        prompt = f"Learner native language: {native_language}\nSentences:\n{numbered}"
        try:
            result = await self._agent.run(prompt)
        except Exception as exc:
            raise TranslationFailed(str(exc)) from exc
        return result.output.translations


@lru_cache
def get_daily_translation_agent() -> DailyTranslationAgent:
    settings = get_settings()
    try:
        return PydanticAIDailyTranslationAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
