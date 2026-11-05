from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from errors import ApiError
from talk.schemas import TalkResponse


class TalkAgent(Protocol):
    async def respond(
        self,
        *,
        native_language: str,
        focus_context: str,
        soul_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> TalkResponse: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You are Named's conversation partner for an English learning app.

Respond naturally to what the learner actually says, stay on the current topic,
and keep the conversation going with relevant questions or gentle help. Use
simple English, and use the learner's native language when explaining meaning or
grammar.

Return one structured response:
- reply: the assistant message. Keep it conversational, not a lecture.
- corrections: optional, only when a clearer or more natural English expression
  would help. Each correction keeps the learner's original wording in `original`,
  gives a `suggestion`, and a short `note` in the learner's native language.
  Never imply the learner was wrong when the original is already natural.
- annotations: useful words or expressions from the exchange, with kind
  ("word" or "expression") and a short `meaning_zh`.
- suggested_expressions: optional expressions the learner could reuse later.
- needs_confirmation: true only when you cannot understand the learner and need
  them to clarify.

Do not invent personal facts, places, people, or feelings the learner did not
provide. Do not infer age, gender, English level, interests, or life experiences.
""".strip()


class PydanticAITalkAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=TalkResponse,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def respond(
        self,
        *,
        native_language: str,
        focus_context: str,
        soul_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> TalkResponse:
        transcript = "\n".join(f"{message['role']}: {message['text']}" for message in history)
        prompt = (
            f"Learner native language: {native_language}\n"
            f"Current focus:\n{focus_context}\n\n"
            f"Known Soul context:\n{soul_context or '(none)'}\n\n"
            f"Conversation so far:\n{transcript or '(new conversation)'}\n\n"
            f"New learner message: {user_text}"
        )
        try:
            result = await self._agent.run(prompt)
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output


@lru_cache
def get_talk_agent() -> TalkAgent:
    settings = get_settings()
    try:
        return PydanticAITalkAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
