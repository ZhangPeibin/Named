from functools import lru_cache
from typing import Protocol

from agents import AgentFailed as AgentFailed
from agents import AgentRuntime, AgentSpec, get_agent_runtime, register
from experience.schemas import ExperienceExtraction


class ExperienceAgent(Protocol):
    async def extract(
        self,
        *,
        native_language: str,
        focus_context: str,
        messages: list[dict[str, str]],
        corrections: list[str],
        annotations: list[str],
    ) -> ExperienceExtraction: ...


SYSTEM_PROMPT = """
You extract durable experiences from an English learner's Talk conversation.

Return at most one life experience and at most one learning experience.

Life experience:
- Only when the learner explicitly shares a real event, relationship, place,
  action, or feeling from their own life.
- Never infer from a practice sentence, hypothetical, role-play, or AI text.
- Do not add facts the learner did not provide.

Learning experience:
- What the learner actually tried, understood, practiced, or corrected in this
  conversation.
- Use corrections and annotations when they are supported by the messages.

For both:
- Write the summary in the learner's native language.
- Write it as a natural, user-facing statement, not as an extraction note.
  Do not start with "Learner", "学习者", or "用户分享".
- Do not mention message numbers or quote the transcript in summary or detail.
- Keep English words and expressions in English.
- Use only evidence from the numbered messages.
- Set evidence_sequences to the message numbers that directly support the
  summary.
- related_terms must be copied from the messages, corrections, or annotations.
- If there is no clear experience, return null for that type. Prefer null over
  guessing.
""".strip()

SPEC = register(
    AgentSpec(
        name="experience",
        prompt_version="experience-v1",
        system_prompt=SYSTEM_PROMPT,
        output_type=ExperienceExtraction,
        error_code="agent_failed",
        error_message="The experience agent failed.",
        max_attempts=1,
    )
)


class PydanticAIExperienceAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def extract(
        self,
        *,
        native_language: str,
        focus_context: str,
        messages: list[dict[str, str]],
        corrections: list[str],
        annotations: list[str],
    ) -> ExperienceExtraction:
        transcript = "\n".join(
            f"[{message['sequence']}] {message['role']}: {message['text']}" for message in messages
        )
        correction_text = "\n".join(f"- {item}" for item in corrections) or "(none)"
        annotation_text = "\n".join(f"- {item}" for item in annotations) or "(none)"
        prompt = (
            f"Learner native language: {native_language}\n"
            f"Focus:\n{focus_context or '(none)'}\n\n"
            f"Conversation:\n{transcript or '(empty)'}\n\n"
            f"Corrections:\n{correction_text}\n\n"
            f"Annotations:\n{annotation_text}"
        )
        return await self._runtime.run(SPEC, prompt)


@lru_cache
def get_experience_agent() -> ExperienceAgent:
    return PydanticAIExperienceAgent(get_agent_runtime())
