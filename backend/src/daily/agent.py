from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from daily.schemas import DailyReadAgentOutput
from errors import ApiError


class DailyReadAgent(Protocol):
    async def write(
        self,
        *,
        target_words: list[str],
        native_language: str,
        theme: str,
        learner_context: str,
    ) -> DailyReadAgentOutput: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You write a short daily reading for the companion's learner in Named.

Write one short, gentle daily reading that gives the learner a reason to listen
and read again.

Requirements:
- Use 220-320 words of simple, natural A2-B1 English.
- Use every target word naturally. Do not force awkward sentences.
- Write 6-10 short sentences.
- Open with a concrete image, small question, or hint of tension.
- Include one small turn, discovery, or change; do not explain a moral.
- Use at least two concrete sensory details.
- End on an image or a quiet line, not a summary of life advice.
- Make the text coherent and pleasant to read aloud.
- Do not mention the learner, the target words, Named, or the exercise.
- Do not invent personal facts about the learner.
- Use the learner context only to choose a fitting theme, tone, and links
  between target words; never state the learner's personal facts as story
  content.
- Return plain text only, with no Markdown.
- title is a short, inviting title.
- question is one optional simple comprehension or reflection question.
- target_words must list only the target words actually used.
""".strip()


class PydanticAIDailyReadAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=DailyReadAgentOutput,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def write(
        self,
        *,
        target_words: list[str],
        native_language: str,
        theme: str,
        learner_context: str,
    ) -> DailyReadAgentOutput:
        prompt = (
            f"Story theme: {theme}\n"
            f"Target words: {', '.join(target_words)}\n"
            f"Learner native language: {native_language}\n\n"
            f"Learner context (do not reuse personal facts as story content):\n"
            f"{learner_context or '(none)'}"
        )
        try:
            result = await self._agent.run(prompt)
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output


@lru_cache
def get_daily_read_agent() -> DailyReadAgent:
    settings = get_settings()
    try:
        return PydanticAIDailyReadAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
