from functools import lru_cache
from typing import Protocol

from agents import AgentFailed as AgentFailed
from agents import AgentRuntime, AgentSpec, get_agent_runtime, register
from sentence.schemas import SentenceAgentOutput


class SentenceAgent(Protocol):
    async def explain(
        self,
        *,
        text: str,
        native_language: str,
    ) -> SentenceAgentOutput: ...


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

SPEC = register(
    AgentSpec(
        name="sentence",
        prompt_version="sentence-v1",
        system_prompt=SYSTEM_PROMPT,
        output_type=SentenceAgentOutput,
        error_code="sentence_agent_failed",
        error_message="The sentence agent failed.",
    )
)


class PydanticAISentenceAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def explain(
        self,
        *,
        text: str,
        native_language: str,
    ) -> SentenceAgentOutput:
        return await self._runtime.run(
            SPEC,
            f"Learner native language: {native_language}\nSelected sentence: {text}",
        )


@lru_cache
def get_sentence_agent() -> SentenceAgent:
    return PydanticAISentenceAgent(get_agent_runtime())
