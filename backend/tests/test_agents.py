import importlib
import logging

import pytest
from pydantic_ai.models.test import TestModel

from agents import AgentFailed, AgentSpec, AgentTimeout, agent_api_error, all_specs
from agents.runtime import AgentRuntime
from agents.testing import FakeAgent
from assistant.schemas import AssistantIntentOut
from config import Settings

AGENT_MODULES = [
    "assistant.agent",
    "discovery.agent",
    "discovery.word_lookup_agent",
    "discovery.word_card_agent",
    "sentence.agent",
    "talk.agent",
    "experience.agent",
    "question.agent",
    "practice.agent",
]

EXPECTED_AGENTS = {
    "intent",
    "discovery",
    "word_lookup",
    "word_card",
    "sentence",
    "talk",
    "help",
    "experience",
    "question",
    "practice",
    "talk_opener",
}


def runtime_for(
    agent: FakeAgent,
    *,
    timeout_seconds: float = 1.0,
    max_attempts: int = 2,
    retry_backoff_seconds: float = 0.0,
) -> AgentRuntime:
    settings = Settings(
        auth_secret="test-secret",
        ai_model="deepseek:deepseek-flash",
        ai_agent_timeout_seconds=timeout_seconds,
        ai_agent_max_attempts=max_attempts,
        ai_agent_retry_backoff_seconds=retry_backoff_seconds,
    )
    return AgentRuntime(None, None, settings, agent_factory=lambda _: agent)


def make_spec(
    *,
    name: str = "runtime-test",
    max_attempts: int | None = None,
    timeout_seconds: float | None = None,
) -> AgentSpec[AssistantIntentOut]:
    return AgentSpec(
        name=name,
        prompt_version="runtime-test-v1",
        system_prompt="Return the requested intent.",
        output_type=AssistantIntentOut,
        error_code="agent_failed",
        error_message="The test agent failed.",
        max_attempts=max_attempts,
        timeout_seconds=timeout_seconds,
    )


def test_registry_contains_every_agent_contract() -> None:
    for module in AGENT_MODULES:
        importlib.import_module(module)

    specs = {spec.name: spec for spec in all_specs()}

    assert set(specs) == EXPECTED_AGENTS
    assert specs["experience"].max_attempts == 1
    assert specs["discovery"].prompt_version is None
    for spec in specs.values():
        assert spec.output_type is not None
        assert spec.system_prompt
        assert spec.error_code
        assert spec.error_message


def test_agent_api_error_uses_spec_contract() -> None:
    spec = make_spec()

    error = agent_api_error(AgentFailed("provider failed"), spec)

    assert error.status_code == 502
    assert error.code == "agent_failed"
    assert error.message == "The test agent failed."


@pytest.mark.asyncio
async def test_runtime_builds_a_pydantic_agent() -> None:
    runtime = AgentRuntime(TestModel(), None, Settings(auth_secret="test-secret"))

    result = await runtime.run(make_spec(name="adapter-test"), "hello")

    assert isinstance(result, AssistantIntentOut)


@pytest.mark.asyncio
async def test_runtime_returns_output_and_logs_usage(caplog) -> None:
    output = AssistantIntentOut(intent="none", confidence=0.9)
    agent = FakeAgent(outputs=[output])
    runtime = runtime_for(agent)

    with caplog.at_level(logging.INFO, logger="named.agent"):
        result = await runtime.run(make_spec(), "hello")

    assert result == output
    assert agent.calls == ["hello"]
    assert "agent run agent=runtime-test" in caplog.text
    assert "prompt_version=runtime-test-v1" in caplog.text
    assert "latency_ms=" in caplog.text
    assert "input_tokens=0 output_tokens=0 outcome=ok" in caplog.text
    assert "hello" not in caplog.text


@pytest.mark.asyncio
async def test_runtime_retries_transient_errors() -> None:
    output = AssistantIntentOut(intent="open_words", confidence=0.8)
    agent = FakeAgent(outputs=[output], errors=[TimeoutError("slow provider")])
    runtime = runtime_for(agent, max_attempts=2)

    result = await runtime.run(make_spec(), "review words")

    assert result == output
    assert len(agent.calls) == 2


@pytest.mark.asyncio
async def test_runtime_does_not_retry_non_transient_errors() -> None:
    agent = FakeAgent(errors=[ValueError("bad output")])
    runtime = runtime_for(agent, max_attempts=3)

    with pytest.raises(AgentFailed) as exc_info:
        await runtime.run(make_spec(), "hello")

    assert not isinstance(exc_info.value, AgentTimeout)
    assert exc_info.value.attempts == 1
    assert len(agent.calls) == 1


@pytest.mark.asyncio
async def test_runtime_exhausts_attempts_on_timeout() -> None:
    agent = FakeAgent(errors=[TimeoutError("slow"), TimeoutError("slow")])
    runtime = runtime_for(agent, max_attempts=2)

    with pytest.raises(AgentTimeout) as exc_info:
        await runtime.run(make_spec(), "hello")

    assert exc_info.value.attempts == 2
    assert len(agent.calls) == 2


@pytest.mark.asyncio
async def test_runtime_passes_timeout_to_agent() -> None:
    output = AssistantIntentOut(intent="none", confidence=1.0)
    agent = FakeAgent(outputs=[output], delay_seconds=0.05)
    runtime = runtime_for(agent, max_attempts=1)

    with pytest.raises(AgentTimeout):
        await runtime.run(make_spec(timeout_seconds=0.01), "hello")

    assert len(agent.calls) == 1


@pytest.mark.asyncio
async def test_spec_max_attempts_overrides_runtime_default() -> None:
    agent = FakeAgent(errors=[TimeoutError("slow"), TimeoutError("slow")])
    runtime = runtime_for(agent, max_attempts=3)

    with pytest.raises(AgentTimeout):
        await runtime.run(make_spec(max_attempts=1), "hello")

    assert len(agent.calls) == 1
