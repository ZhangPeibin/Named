import pytest
import pytest_asyncio
from test_discovery import FakeDiscoveryAgent, FakeTTSProvider, request_and_verify
from test_talk import FakeTalkAgent, talk_client

from main import app
from question.agent import get_question_agent
from question.schemas import QuestionAgentOutput


class FakeQuestionAgent:
    def __init__(self) -> None:
        self.calls: list[dict[str, object]] = []

    async def ask(
        self,
        *,
        text: str,
        native_language: str,
        context_type: str | None = None,
        context_quote: str | None = None,
        history: list[dict[str, str]] | None = None,
    ) -> QuestionAgentOutput:
        self.calls.append(
            {
                "text": text,
                "native_language": native_language,
                "context_type": context_type,
                "context_quote": context_quote,
                "history": history or [],
            }
        )
        return QuestionAgentOutput(
            answer=f"Simple answer to: {text}",
            example="A short example.",
            native_explanation=f"Native explanation for: {text}",
            confidence="high",
            follow_up_suggestions=["Could I use will instead?"],
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


def headers_for(verified: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {verified['session_token']}"}


@pytest.mark.asyncio
async def test_question_thread_context_and_follow_up(question_env) -> None:
    http, sender, agent = question_env
    verified = await request_and_verify(http, sender, "question@example.com")
    headers = headers_for(verified)

    response = await http.post(
        "/api/v1/questions",
        headers=headers,
        json={
            "text": "Why is would used here?",
            "context": {
                "type": "sentence",
                "ref": "sentence-1",
                "quote": "If I had time, I would read more.",
            },
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["title"] == "Why is would used here?"
    assert body["context_type"] == "sentence"
    assert body["context_quote"] == "If I had time, I would read more."
    assert [message["role"] for message in body["messages"]] == [
        "user",
        "assistant",
    ]
    assert body["messages"][1]["example"] == "A short example."
    assert body["messages"][1]["confidence"] == "high"
    assert body["messages"][1]["follow_up_suggestions"] == ["Could I use will instead?"]
    assert agent.calls[0]["context_quote"] == "If I had time, I would read more."

    follow_up = await http.post(
        f"/api/v1/questions/{body['id']}/messages",
        headers=headers,
        json={"text": "Could I use will instead?"},
    )
    assert follow_up.status_code == 200, follow_up.text
    followed = follow_up.json()
    assert len(followed["messages"]) == 4
    assert followed["messages"][2]["text"] == "Could I use will instead?"
    assert agent.calls[1]["history"][-1]["text"].startswith("Simple answer")

    assistant = followed["messages"][-1]
    feedback = await http.post(
        f"/api/v1/questions/{body['id']}/messages/{assistant['id']}/feedback",
        headers=headers,
        json={"feedback": "helpful"},
    )
    assert feedback.status_code == 200, feedback.text
    assert feedback.json()["feedback"] == "helpful"

    timeline = await http.get("/api/v1/timeline", headers=headers)
    assert timeline.status_code == 200, timeline.text
    question_items = [item for item in timeline.json()["items"] if item["type"] == "question"]
    assert len(question_items) == 1
    assert question_items[0]["id"] == body["id"]
    assert question_items[0]["last_text"].startswith("Simple answer")

    listed = await http.get("/api/v1/questions", headers=headers)
    assert listed.status_code == 200, listed.text
    item = listed.json()["items"][0]
    assert item["id"] == body["id"]
    assert item["last_text"].startswith("Simple answer")

    loaded = await http.get(f"/api/v1/questions/{body['id']}", headers=headers)
    assert loaded.status_code == 200, loaded.text
    assert len(loaded.json()["messages"]) == 4

    deleted = await http.delete(f"/api/v1/questions/{body['id']}", headers=headers)
    assert deleted.status_code == 204
    missing = await http.get(f"/api/v1/questions/{body['id']}", headers=headers)
    assert missing.status_code == 404
    timeline = await http.get("/api/v1/timeline", headers=headers)
    assert all(item["type"] != "question" for item in timeline.json()["items"])


@pytest.mark.asyncio
async def test_questions_require_auth(question_env) -> None:
    http, _, _ = question_env
    response = await http.get("/api/v1/questions")
    assert response.status_code == 401
