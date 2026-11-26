from functools import lru_cache
from typing import Protocol

from agents import AgentFailed as AgentFailed
from agents import AgentRuntime, AgentSpec, get_agent_runtime, register
from discovery.schemas import WordPayload

WORD_CARD_PROMPT_VERSION = "word-card-v1"


class WordCardAgent(Protocol):
    async def generate(self, *, word: str, native_language: str) -> WordPayload: ...


SYSTEM_PROMPT = """
You build the first compact card for a known English word in an English learning app.

The learner has already selected one English word. Return only the fields needed for
the first card:

- spelling: exactly the given word
- ipa: US/UK IPA only when confident; otherwise leave the object empty
- pos: one or two parts of speech
- senses: one or two senses, each with a simple English definition, a native-language
  translation, one natural English example, and the native-language example
- chunks: one or two common natural chunks, each with a native-language meaning and
  an English example

Leave grammar, related, variety_notes, and scene_extensions empty. They are generated
later when the learner opens the full details.

Rules:
- Never invent IPA, definitions, or grammar. Use null or empty values when unsure.
- Use the learner's native language for all native-language fields, including
  definition_zh and example_zh. Do not assume the learner's native language is Chinese.
- Keep definitions and examples simple and natural. Use American English for examples.
- Do not use Markdown. Return only the structured result.
""".strip()

SPEC = register(
    AgentSpec(
        name="word_card",
        prompt_version=WORD_CARD_PROMPT_VERSION,
        system_prompt=SYSTEM_PROMPT,
        output_type=WordPayload,
        error_code="word_card_failed",
        error_message="The word card agent failed.",
    )
)


class PydanticAIWordCardAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def generate(self, *, word: str, native_language: str) -> WordPayload:
        return await self._runtime.run(
            SPEC,
            f"Word: {word}\nLearner native language: {native_language}",
        )


@lru_cache
def get_word_card_agent() -> WordCardAgent:
    return PydanticAIWordCardAgent(get_agent_runtime())
