from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from assistant.schemas import AssistantIntentOut
from config import Settings, get_settings
from errors import ApiError


class IntentAgent(Protocol):
    async def route(self, text: str) -> AssistantIntentOut: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You are Named's input router for an English learning app.

Decide whether the learner's message is a request to operate the app or ordinary
learning content. The learner may write in English, Chinese, or a mix of both.

Return exactly one intent:

- review_words: the learner wants to review or practise their saved words.
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
- Do not require exact wording. Understand natural phrasing, typos, and mixed
  Chinese/English.
- If you are not confident, return none instead of guessing.
- confidence is your confidence in the chosen intent, from 0 to 1.
""".strip()


class PydanticAIIntentAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=AssistantIntentOut,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def route(self, text: str) -> AssistantIntentOut:
        try:
            result = await self._agent.run(f"Learner message: {text}")
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output


@lru_cache
def get_intent_agent() -> IntentAgent:
    settings = get_settings()
    try:
        return PydanticAIIntentAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
