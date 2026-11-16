from functools import lru_cache
from typing import Protocol

from agents import AgentFailed as AgentFailed
from agents import AgentRuntime, AgentSpec, get_agent_runtime, register
from question.schemas import QuestionAgentOutput


class QuestionAgent(Protocol):
    async def ask(self, *, text: str, native_language: str) -> QuestionAgentOutput: ...


SYSTEM_PROMPT = """
You answer a learner's question for an English learning app.

Answer rules:
- Answer the actual question directly and concisely.
- Use simple, natural English for the English explanation.
- If the learner writes in Chinese or mixed language, still answer in simple English first.
- Put a clear explanation in the learner's native language in native_explanation.
- Use examples when they make the answer easier to understand.
- Do not use Markdown.
- Do not invent facts. If you are unsure, say what is uncertain.
- Do not turn the answer into a generic lesson or a list of unrelated tips.
- Keep the total answer under 220 words unless the question truly needs more.
""".strip()

SPEC = register(
    AgentSpec(
        name="question",
        prompt_version="question-v1",
        system_prompt=SYSTEM_PROMPT,
        output_type=QuestionAgentOutput,
        error_code="question_agent_failed",
        error_message="The question agent failed.",
    )
)


class PydanticAIQuestionAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def ask(self, *, text: str, native_language: str) -> QuestionAgentOutput:
        return await self._runtime.run(
            SPEC,
            f"Learner native language: {native_language}\nQuestion: {text}",
        )


@lru_cache
def get_question_agent() -> QuestionAgent:
    return PydanticAIQuestionAgent(get_agent_runtime())
