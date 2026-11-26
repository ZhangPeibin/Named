from functools import lru_cache
from typing import Literal, Protocol

from pydantic import BaseModel

from agents import AgentRuntime, AgentSpec, get_agent_runtime, register


class PresenceContext(BaseModel):
    activity: Literal["none", "commute", "study", "work", "rest", "home"] = "none"
    topic: Literal["none", "recent_word", "recent_talk", "hobby"] = "none"
    mood: Literal["calm", "curious", "encouraging"] = "calm"


class PresenceAgent(Protocol):
    async def analyze(
        self,
        *,
        time_bucket: str,
        learner_context: str,
        companion_name: str | None,
        companion_hobby: str | None,
        recent_word: str | None,
        days_since_last_talk: int | None,
    ) -> PresenceContext: ...


PRESENCE_PROMPT = """
You choose the next small line for the companion in Named's Timeline.
You do not write the line. Return structured fields only.

Use only explicit learner data. Never infer school, work, location, age, or routine
from the time of day.
If the learner explicitly shared a routine, you may set activity to match it.

Choose one topic:
- recent_word: only when a recent saved word is supplied and it fits.
- recent_talk: only when a recent talk is supplied and it fits.
- hobby: only when the companion hobby is supplied and it fits.
- none: otherwise.

Keep mood calm unless the context clearly calls for curiosity or encouragement.
""".strip()

PRESENCE_SPEC = register(
    AgentSpec(
        name="companion_presence",
        prompt_version="presence-v1",
        system_prompt=PRESENCE_PROMPT,
        output_type=PresenceContext,
        error_code="presence_agent_failed",
        error_message="The companion presence agent failed.",
    )
)


class PydanticAIPresenceAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def analyze(
        self,
        *,
        time_bucket: str,
        learner_context: str,
        companion_name: str | None,
        companion_hobby: str | None,
        recent_word: str | None,
        days_since_last_talk: int | None,
    ) -> PresenceContext:
        prompt = (
            f"Time of day: {time_bucket}\n"
            f"Companion name: {companion_name or '(none)'}\n"
            f"Companion hobby: {companion_hobby or '(none)'}\n"
            f"Recent word: {recent_word or '(none)'}\n"
            f"Days since last talk: "
            f"{days_since_last_talk if days_since_last_talk is not None else '(none)'}\n\n"
            f"Learner context (do not quote or reveal it):\n"
            f"{learner_context or '(none)'}"
        )
        return await self._runtime.run(PRESENCE_SPEC, prompt)


@lru_cache
def get_presence_agent() -> PresenceAgent:
    return PydanticAIPresenceAgent(get_agent_runtime())
