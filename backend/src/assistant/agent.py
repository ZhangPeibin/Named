from functools import lru_cache
from typing import Protocol

from agents import AgentFailed as AgentFailed
from agents import AgentRuntime, AgentSpec, get_agent_runtime, register
from assistant.schemas import AssistantIntentOut


class IntentAgent(Protocol):
    async def route(self, text: str) -> AssistantIntentOut: ...


SYSTEM_PROMPT = """
You are Named's input router for an English learning app.

Decide whether the learner's message is a request to operate the app or ordinary
learning content. The learner may write in English, Chinese, or a mix of both.

Return exactly one intent:

- open_words: the learner wants to see or browse their saved words.
  Examples: "my words", "show my words", "open my vocabulary",
  "看看我的单词", "我的词汇", "打开词语列表".
  Examples: "review words", "review my vocabulary", "我要复习单词",
  "帮我复习一下词语", "practice my words".
- start_challenge: the learner wants to begin a new challenge.
  Examples: "start a challenge", "start challenge", "开始一个 challenge",
  "我要开始挑战", "帮我开一轮挑战".
- view_challenges: the learner wants to see their challenges or challenge status.
  Examples: "show my challenge", "看看我的 challenge", "我的挑战怎么样了",
  "查看挑战".
- none: the message is normal learning content, a question, a sentence to
  translate/improve, or is ambiguous.

Rules:
- Route only when the learner clearly asks to control the app.
- Ordinary content that mentions challenge or review is none. For example,
  "What does challenge mean?", "I want to talk about my challenge",
  "review 是什么意思", and "昨天我参加了一个 challenge" are none.
- A bare ambiguous word such as "challenge" or "review" is none unless the
  surrounding message clearly asks to start/view/review.
- Distinguish starting from viewing: "开始 challenge" is start_challenge;
  "看看/查看 challenge" is view_challenges.
- Distinguish viewing words from reviewing words: "my words/看看我的单词" is
  open_words; "practice words/练词" is open_words.
- Do not require exact wording. Understand natural phrasing, typos, and mixed
  Chinese/English.
- If you are not confident, return none instead of guessing.
- confidence is your confidence in the chosen intent, from 0 to 1.
""".strip()

SPEC = register(
    AgentSpec(
        name="intent",
        prompt_version="intent-v1",
        system_prompt=SYSTEM_PROMPT,
        output_type=AssistantIntentOut,
        error_code="agent_failed",
        error_message="The assistant could not route this message.",
    )
)


class PydanticAIIntentAgent:
    def __init__(self, runtime: AgentRuntime) -> None:
        self._runtime = runtime

    async def route(self, text: str) -> AssistantIntentOut:
        return await self._runtime.run(SPEC, f"Learner message: {text}")


@lru_cache
def get_intent_agent() -> IntentAgent:
    return PydanticAIIntentAgent(get_agent_runtime())
