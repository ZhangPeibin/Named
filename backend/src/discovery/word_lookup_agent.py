from functools import lru_cache
from typing import Protocol

from pydantic import BaseModel, Field

from agents import AgentFailed as AgentFailed
from agents import AgentRuntime, AgentSpec, get_agent_runtime, register


class WordLookupOutput(BaseModel):
    english_word: str = Field(min_length=1, max_length=200)


class WordLookupAgent(Protocol):
    async def resolve(self, *, text: str, native_language: str) -> str: ...


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

SPEC = register(
    AgentSpec(
        name="word_lookup",
        prompt_version="word-lookup-v1",
        system_prompt=SYSTEM_PROMPT,
        output_type=WordLookupOutput,
        error_code="word_lookup_failed",
        error_message="The word lookup agent failed.",
    )
)


class PydanticAIWordLookupAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def resolve(self, *, text: str, native_language: str) -> str:
        output = await self._runtime.run(
            SPEC,
            f"Learner native language: {native_language}\nSelected text: {text}",
        )
        return output.english_word.strip()


@lru_cache
def get_word_lookup_agent() -> WordLookupAgent:
    return PydanticAIWordLookupAgent(get_agent_runtime())
