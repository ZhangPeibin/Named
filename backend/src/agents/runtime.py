import asyncio
import logging
import time
from collections.abc import Callable
from typing import Any, Protocol, TypeVar

from pydantic import BaseModel
from pydantic_ai import Agent
from pydantic_ai.exceptions import (
    ModelAuthenticationError,
    ModelConnectionError,
    ModelContextWindowExceededError,
    ModelNotFoundError,
    ModelRateLimitError,
    ModelRequestRejectedError,
    ModelServerError,
    ModelUnavailableError,
    UsageLimitExceeded,
    UserError,
)

from agents.errors import AgentFailed, AgentTimeout
from agents.spec import AgentSpec
from config import Settings

OutputT = TypeVar("OutputT", bound=BaseModel)

logger = logging.getLogger("named.agent")


class RunnableAgent(Protocol):
    async def run(self, prompt: Any, *, timeout: float | None = None) -> Any: ...


AgentFactory = Callable[[AgentSpec[Any]], RunnableAgent]

_NON_RETRYABLE = (
    ModelAuthenticationError,
    ModelContextWindowExceededError,
    ModelNotFoundError,
    ModelRequestRejectedError,
    UsageLimitExceeded,
    UserError,
)

_RETRYABLE = (
    TimeoutError,
    ModelConnectionError,
    ModelRateLimitError,
    ModelServerError,
    ModelUnavailableError,
)


def is_retryable_error(error: BaseException) -> bool:
    if isinstance(error, _NON_RETRYABLE):
        return False
    return isinstance(error, _RETRYABLE)


class AgentRuntime:
    def __init__(
        self,
        model: Any,
        model_settings: Any,
        settings: Settings,
        *,
        agent_factory: AgentFactory | None = None,
    ) -> None:
        self._model = model
        self._model_settings = model_settings
        self._settings = settings
        self._agent_factory = agent_factory or self._build_pydantic_agent
        self._agents: dict[str, RunnableAgent] = {}

    def _build_pydantic_agent(self, spec: AgentSpec[Any]) -> RunnableAgent:
        return Agent(
            self._model,
            output_type=spec.output_type,
            system_prompt=spec.system_prompt,
            name=spec.name,
            model_settings=self._model_settings,
        )

    def agent_for(self, spec: AgentSpec[Any]) -> RunnableAgent:
        agent = self._agents.get(spec.name)
        if agent is None:
            agent = self._agent_factory(spec)
            self._agents[spec.name] = agent
        return agent

    async def run(self, spec: AgentSpec[OutputT], prompt: Any) -> OutputT:
        agent = self.agent_for(spec)
        timeout = (
            spec.timeout_seconds
            if spec.timeout_seconds is not None
            else self._settings.ai_agent_timeout_seconds
        )
        max_attempts = max(
            1,
            spec.max_attempts
            if spec.max_attempts is not None
            else self._settings.ai_agent_max_attempts,
        )
        prompt_version = spec.prompt_version or self._settings.ai_prompt_version
        started_at = time.perf_counter()

        attempt = 0
        while attempt < max_attempts:
            attempt += 1
            try:
                result = await agent.run(prompt, timeout=timeout)
            except Exception as exc:
                retryable = is_retryable_error(exc)
                logger.warning(
                    "agent run failed agent=%s prompt_version=%s model=%s attempt=%d "
                    "retryable=%s error=%s",
                    spec.name,
                    prompt_version,
                    self._settings.ai_model,
                    attempt,
                    retryable,
                    type(exc).__name__,
                )
                if retryable and attempt < max_attempts:
                    await asyncio.sleep(self._settings.ai_agent_retry_backoff_seconds * attempt)
                    continue
                raise self._failure(spec, attempt, exc) from exc

            usage = getattr(result, "usage", None)
            logger.info(
                "agent run agent=%s prompt_version=%s model=%s attempt=%d latency_ms=%.1f "
                "input_tokens=%s output_tokens=%s outcome=ok",
                spec.name,
                prompt_version,
                self._settings.ai_model,
                attempt,
                (time.perf_counter() - started_at) * 1000,
                getattr(usage, "input_tokens", None),
                getattr(usage, "output_tokens", None),
            )
            return result.output

        raise AssertionError("Agent runtime exhausted attempts without a result.")

    def _failure(self, spec: AgentSpec[Any], attempt: int, exc: Exception) -> AgentFailed:
        message = f"{spec.name} agent failed"
        if isinstance(exc, TimeoutError):
            return AgentTimeout(message, agent=spec.name, attempts=attempt)
        return AgentFailed(message, agent=spec.name, attempts=attempt)
