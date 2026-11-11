from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from errors import ApiError
from sentence.schemas import SentenceAgentOutput


class SentenceAgent(Protocol):
    async def explain(
        self,
        *,
        text: str,
        native_language: str,
    ) -> SentenceAgentOutput: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You explain a selected English or Chinese sentence to an English learner.

Return:
- natural_english: the complete, accurate English version. If the input is
  already natural English, preserve it. If it is Chinese or mixed language,
  express exactly its meaning in natural English.
- explanation_native: a short explanation in the learner's native language.
- grammar_notes: concise, reusable grammar or structure notes in the learner's
  native language.
- chunks: up to 4 reusable phrase chunks with a native-language meaning and an
  optional English example.
- key_words: up to 6 important words with part of speech and a short
  native-language meaning.

Rules:
- Preserve names, facts, tone, and the learner's intended meaning.
- Do not add events, places, people, or feelings the learner did not provide.
- Do not use Markdown.
- Do not provide a separate line-by-line translation of the whole sentence.
- Prefer a useful explanation over a literal word-for-word rewrite.
""".strip()


class PydanticAISentenceAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=SentenceAgentOutput,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def explain(
        self,
        *,
        text: str,
        native_language: str,
    ) -> SentenceAgentOutput:
        try:
            result = await self._agent.run(
                f"Learner native language: {native_language}\nSelected sentence: {text}"
            )
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output


@lru_cache
def get_sentence_agent() -> SentenceAgent:
    settings = get_settings()
    try:
        return PydanticAISentenceAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
