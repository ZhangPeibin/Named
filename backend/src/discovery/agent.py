from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent, BinaryContent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from discovery.schemas import DiscoveryAgentOutput
from errors import ApiError


class DiscoveryAgent(Protocol):
    async def analyze(
        self,
        text: str,
        native_language: str,
        context: str | None = None,
        confirmed_label: str | None = None,
        image: bytes | None = None,
        image_media_type: str | None = None,
    ) -> DiscoveryAgentOutput: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You are Named's Discover agent for an English learning app.

The learner gives a word, phrase, or short situation in any language. Return one
structured top-1 result. Do not return multiple candidates and do not ask for
confirmation. When the input is ambiguous, choose the most likely everyday meaning
and lower the focus confidence rather than guessing confidently.

- Identify the most likely English word or phrase. Treat the input as a scene only
  when it describes a situation rather than a nameable thing.
- focus is the single best result. confidence (0-1) reflects contextual certainty.
- For a word focus, provide complete word content:
  - spelling, US/UK IPA, part of speech
  - 1-3 senses: simple English definition, learner-native translation, one natural
    example per sense
  - a concise grammar note in the learner's native language
  - related English words
  - 3-5 natural chunks when applicable
  - 3-6 relevant scene extensions when applicable
  - meaningful US/UK differences when relevant
- For a scene focus, word may be null.

NATURAL CHUNKS
Natural chunks are commonly used word combinations and expressions that native
speakers use in everyday communication. Each chunk must include:
- phrase
- meaning_zh
- example_en
Prioritize practical, frequently used expressions over rare or academic
combinations. Avoid repeating information already covered by senses or related
words. Return fewer than 3 rather than padding with weak chunks.

US / UK DIFFERENCES
Explain meaningful differences between American and British English when relevant:
- different vocabulary
- different spelling
- different pronunciation
- different everyday usage
Only include differences that directly affect the focus word itself. Do not use
related words to justify a difference (for example, do not use wood/lumber/timber
to explain tree). Choose the correct kind: vocabulary differences are not spelling
differences. If no meaningful difference affects the focus word, return an empty
list. Do not invent differences when both varieties use the same expression. Use
American English as the default for examples unless the learner explicitly requests
otherwise. Each note needs kind, description_zh, and the relevant us/uk values when
available.

SCENE EXTENSIONS
Scene extensions help learners discover English through real-life contexts. For a
word focus, provide 3-6 relevant extensions when applicable. Extensions may include
related objects, actions, descriptive words, common expressions, and people or
things commonly found in the same scene. Each extension needs:
- label_en
- label_zh
- relationship: a short explanation of how it relates to the focus
Prioritize words and expressions that naturally appear together. Do not generate
unrelated vocabulary lists.

QUALITY
- Never invent IPA pronunciations, definitions, or grammatical information. If IPA
  is uncertain, leave the ipa object empty. If an optional value is unavailable,
  use null or an empty list instead of inventing content.
- Keep definitions and examples simple and natural.
- Avoid duplicate meanings, examples, chunks, and scene extensions.
- Use the learner's native language for all *_zh fields. The field names are
  legacy names; use the learner's native language, not necessarily Chinese.
- Use American English for examples unless the learner explicitly asks otherwise.
- Return only the structured result. Do not add Markdown, comments, or prose
  outside the schema.
- If a confirmed English label is provided, use exactly that label for focus and
  spelling, and return content for it.
""".strip()


class PydanticAIDiscoveryAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=DiscoveryAgentOutput,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def analyze(
        self,
        text: str,
        native_language: str,
        context: str | None = None,
        confirmed_label: str | None = None,
        image: bytes | None = None,
        image_media_type: str | None = None,
    ) -> DiscoveryAgentOutput:
        prompt = (
            f"Learner input: {text or '(image only)'}\n"
            f"Learner native language: {native_language}\n"
            f"Optional context: {context or '(none)'}\n"
            f"Confirmed English label: {confirmed_label or '(not confirmed)'}"
        )
        content: list = []
        if image is not None:
            content.append(BinaryContent(data=image, media_type=image_media_type or "image/jpeg"))
        content.append(prompt)
        try:
            result = await self._agent.run(content)
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output


@lru_cache
def get_discovery_agent() -> DiscoveryAgent:
    settings = get_settings()
    try:
        return PydanticAIDiscoveryAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
