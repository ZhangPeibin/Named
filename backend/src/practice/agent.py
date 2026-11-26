from functools import lru_cache
from typing import Protocol

from agents import AgentRuntime, AgentSpec, get_agent_runtime, register
from agents.persona import companion_prompt
from practice.schemas import PracticeReplyOut


class PracticeAgent(Protocol):
    async def respond(
        self,
        *,
        word: str,
        context: str | None,
        native_language: str,
        companion_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> PracticeReplyOut: ...


SYSTEM_PROMPT = companion_prompt("""
The learner is practicing one saved English word by using it in a short
conversation about their own life. The conversation lasts two learner turns.

Conversation style:
- Respond to the learner's meaning first.
- Reply in 1-2 short sentences, about 35 words or fewer.
- Ask exactly one short follow-up question.
- Use simple, natural A2-B1 English.
- Use the target word at most once, and only when it fits naturally.
- Never say "practice", "exercise", "target word", or "let's practice".
- Do not invent personal facts, places, people, or feelings.
- Do not replace the learner's sentence.

Recast:
- Set `recast` to a more natural version of the learner's latest sentence.
- Preserve the learner's meaning and stay close to their words.
- Return null when the sentence is already natural or when a recast would
  change the meaning.
- Do not explain the recast.

native_reply:
- Give a faithful translation of `reply` into the learner's native language.
- Leave it null when the learner's native language is English.

Output fields:
- reply: the assistant message in English. Plain text only.
- recast: the optional natural version of the learner's sentence.
- native_reply: the optional translation of reply.
""")


SPEC = register(
    AgentSpec(
        name="practice",
        prompt_version="practice-v2",
        system_prompt=SYSTEM_PROMPT,
        output_type=PracticeReplyOut,
        error_code="practice_agent_failed",
        error_message="The practice conversation failed.",
    )
)


class PydanticAIPracticeAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def respond(
        self,
        *,
        word: str,
        context: str | None,
        native_language: str,
        companion_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> PracticeReplyOut:
        lines = [f"Target word: {word}", companion_context]
        if context:
            lines.append(f'Learner\'s original context: "{context}"')
        lines.append(f"Learner's native language: {native_language}")
        if history:
            lines.append("Conversation so far:")
            lines.extend(f"- {item['role']}: {item['text']}" for item in history)
        else:
            lines.append("Conversation so far: none")
        lines.append(f"Learner's latest message: {user_text}")
        return await self._runtime.run(SPEC, "\n".join(lines))


@lru_cache
def get_practice_agent() -> PracticeAgent:
    return PydanticAIPracticeAgent(get_agent_runtime())
