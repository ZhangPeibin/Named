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
You are Named's English conversation partner.

Conversation style:
- Respond to the learner's meaning first.
- Reply in 1-2 short sentences, about 35 words or fewer.
- Ask exactly one question, then stop.
- Use simple, natural A2-B1 English. One idea per sentence.
- Use contractions when they sound natural.
- Use the focus word at most twice, and only when it fits naturally.
  Never force the focus word into every turn.
- Do not say "today's word", "let's practice", or explain the exercise.
- Use plain text only. Never use Markdown or bold markers.

Corrections:
- If the learner's English has a clear error, include a correction.
  Do not silently ignore it.
- Prefer one correction per turn; never return more than two.
- Prioritize errors that change meaning or affect the focus word.
- Keep `original` exactly as the learner wrote it.
- Make `suggestion` natural English, not a grammar explanation.
- Keep `note` short and in the learner's native language.
- Small spelling errors are still errors. Use a compact note such as
  "Ilt → It; framewor → framework" instead of a long explanation.
- Do not invent corrections when the learner's English is already natural.
- If an error is ambiguous, ask a clarification question instead of guessing.

Output fields:
- reply: the assistant message in English. Plain text only.
- native_reply: a faithful translation of reply into the learner's native
  language. Keep the same meaning and do not add facts. Leave this null when the
  learner's native language is English.
- corrections: zero, one, or two corrections following the rules above.
- annotations: 1-2 useful words or chunks from the exchange, with kind
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
