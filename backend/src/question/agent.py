from functools import lru_cache
from typing import Protocol

from agents import AgentFailed as AgentFailed
from agents import AgentRuntime, AgentSpec, get_agent_runtime, register
from question.schemas import QuestionAgentOutput


class QuestionHistoryItem(Protocol):
    role: str
    text: str


class QuestionAgent(Protocol):
    async def ask(
        self,
        *,
        text: str,
        native_language: str,
        context_type: str | None = None,
        context_quote: str | None = None,
        history: list[dict[str, str]] | None = None,
    ) -> QuestionAgentOutput: ...


SYSTEM_PROMPT = """
You answer a learner's question for an English learning app.

The learner may ask about a word, sentence, grammar point, situation, or
something they are curious about. They may write in English, Chinese, or mixed
language.

Answer rules:
- Answer the actual question directly and concisely.
- Use simple, natural English for the answer.
- Add one short example only when it genuinely helps.
- Put a clear explanation in the learner's native language in native_explanation.
- Use the supplied context when it exists. Do not ignore the selected quote.
- For a follow-up, use the previous turns and stay on the same topic.
- Do not use Markdown.
- Do not invent facts. If you are unsure, set confidence to low and say what is uncertain.
- Do not turn the answer into a generic lesson or unrelated tips.
- Keep the answer under 220 words unless the question truly needs more.
- follow_up_suggestions are optional, maximum 2, and should be short.
""".strip()

SPEC = register(
    AgentSpec(
        name="question",
        prompt_version="question-v2",
        system_prompt=SYSTEM_PROMPT,
        output_type=QuestionAgentOutput,
        error_code="question_agent_failed",
        error_message="The question agent failed.",
    )
)


class PydanticAIQuestionAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def ask(
        self,
        *,
        text: str,
        native_language: str,
        context_type: str | None = None,
        context_quote: str | None = None,
        history: list[dict[str, str]] | None = None,
    ) -> QuestionAgentOutput:
        lines = [f"Learner native language: {native_language}"]
        if context_type and context_quote:
            lines.append(f"Context type: {context_type}")
            lines.append(f"Selected quote: {context_quote}")
        if history:
            lines.append("Previous turns:")
            for item in history:
                lines.append(f"{item['role']}: {item['text']}")
        lines.append(f"Latest question: {text}")
        return await self._runtime.run(SPEC, "\n".join(lines))


@lru_cache
def get_question_agent() -> QuestionAgent:
    return PydanticAIQuestionAgent(get_agent_runtime())
