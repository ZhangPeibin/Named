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
structured result:
- Identify the most likely English word or phrase, or treat the input as a scene.
- Return 1-5 candidates ordered by likelihood. Each candidate needs label_en,
  label_zh, confidence (0-1), and a short reason in the learner's native language.
- focus is the best candidate, or a scene when the input describes an event or
  situation rather than a single thing.
- needs_confirmation must be true when more than one candidate is plausible,
  confidence is below 0.85, or the input is ambiguous.
- For a word focus, provide full word content: spelling, US/UK IPA, part of speech,
  1-3 senses with simple English definitions and the learner's native language
  translations, one natural example per sense, a grammar note in the learner's
  native language, related English words, and English scene extensions.
- For a scene focus, word may be null.

Never invent personal facts about the learner. Do not infer age, gender, English
level, interests, or life experiences. Keep definition_en and example_en simple.
Use the learner's native language for the *_zh fields and grammar notes.
If a confirmed English label is provided, use exactly that label for focus and
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
