import pytest
import pytest_asyncio
from test_discovery import FakeDiscoveryAgent, FakeTTSProvider, request_and_verify
from test_talk import FakeTalkAgent, talk_client

from main import app
from question.agent import get_question_agent
from question.schemas import QuestionAgentOutput


class FakeQuestionAgent:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []

    async def ask(self, *, text: str, native_language: str) -> QuestionAgentOutput:
        self.calls.append((text, native_language))
        return QuestionAgentOutput(
            answer=f"Simple answer to: {text}",
            native_explanation=f"Native explanation for: {text}",
        )


@pytest_asyncio.fixture
async def question_env(tmp_path):
    async with talk_client(
        FakeDiscoveryAgent(),
        FakeTalkAgent(),
        FakeTTSProvider(),
        str(tmp_path),
    ) as (http, sender, _):
        agent = FakeQuestionAgent()
        app.dependency_overrides[get_question_agent] = lambda: agent
        try:
            yield http, sender, agent
        finally:
            app.dependency_overrides.pop(get_question_agent, None)


@pytest.mark.asyncio
async def test_question_is_answered_and_listed(question_env) -> None:
    http, sender, agent = question_env
    verified = await request_and_verify(http, sender, "question@example.com")
    headers = {"Authorization": f"Bearer {verified['session_token']}"}

    response = await http.post(
        "/api/v1/questions",
        headers=headers,
        json={"text": "Why do we say would here?"},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["question"] == "Why do we say would here?"
    assert body["answer"].startswith("Simple answer")
    assert body["native_explanation"].startswith("Native explanation")
    assert agent.calls == [("Why do we say would here?", "zh")]

    listed = await http.get("/api/v1/questions", headers=headers)
    assert listed.status_code == 200, listed.text
    assert listed.json()["items"][0]["id"] == body["id"]


@pytest.mark.asyncio
async def test_questions_require_auth(question_env) -> None:
    http, _, _ = question_env
    response = await http.get("/api/v1/questions")
    assert response.status_code == 401
