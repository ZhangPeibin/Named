import pytest
import pytest_asyncio
from test_discovery import FakeDiscoveryAgent, FakeTTSProvider, word_output
from test_talk import FakeTalkAgent, bearer, request_and_verify, talk_client

from agents.errors import AgentFailed
from main import app
from practice.agent import get_practice_agent
from practice.schemas import PracticeReplyOut
from practice.service import pick_weighted, practice_weight


class FakePracticeAgent:
    def __init__(self) -> None:
        self.calls: list[dict] = []
        self.fail = False

    async def respond(self, *, word, context, native_language, history, user_text):
        self.calls.append(
            {
                "word": word,
                "context": context,
                "native_language": native_language,
                "history": history,
                "user_text": user_text,
            }
        )
        if self.fail:
            raise AgentFailed("practice agent failed")
        return PracticeReplyOut(
            reply=f"How often do you see a {word}?",
            recast="I saw a tree yesterday.",
            native_reply="你多久看到一次树？",
        )


@pytest_asyncio.fixture
async def practice_env(tmp_path):
    agent = FakeDiscoveryAgent()
    practice_agent = FakePracticeAgent()
    async with talk_client(
        agent,
        FakeTalkAgent(),
        FakeTTSProvider(),
        str(tmp_path),
    ) as (http, sender, _):
        app.dependency_overrides[get_practice_agent] = lambda: practice_agent
        yield http, sender, agent, practice_agent


async def create_saved_word(http, headers, agent, text: str, label: str) -> str:
    agent.output = word_output(label)
    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": text, "context": f"I saw a {label} today."},
    )
    assert response.status_code == 201, response.text
    return response.json()["word_id"]


async def create_two_words(http, sender, agent) -> tuple[dict[str, str], str, str]:
    verified = await request_and_verify(http, sender, "practice@example.com")
    headers = bearer(verified["session_token"])
    tree_id = await create_saved_word(http, headers, agent, "树", "tree")
    river_id = await create_saved_word(http, headers, agent, "river", "river")
    return headers, tree_id, river_id


def test_practice_weight_prefers_unpracticed_words() -> None:
    assert practice_weight(0) == 1.0
    assert practice_weight(1) == 0.5
    assert practice_weight(3) == 0.25


def test_pick_weighted_uses_inverse_practice_count(monkeypatch) -> None:
    captured: dict[str, list[float]] = {}

    def fake_choices(population, weights, k):
        captured["weights"] = weights
        return [population[0]]

    monkeypatch.setattr("practice.service.random.choices", fake_choices)

    assert pick_weighted(["a", "b"], {"a": 0, "b": 3}) == "a"
    assert captured["weights"] == [1.0, 0.25]


@pytest.mark.asyncio
async def test_next_returns_saved_word_with_context_and_options(practice_env) -> None:
    http, sender, agent, _ = practice_env
    headers, tree_id, river_id = await create_two_words(http, sender, agent)

    response = await http.get("/api/v1/practice/next", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()

    assert body["id"] in {tree_id, river_id}
    assert body["practice_count"] == 0
    assert body["context"]
    assert body["audio"] is not None
    other_label = "river" if body["id"] == tree_id else "tree"
    assert body["options"] == [other_label]


@pytest.mark.asyncio
async def test_complete_increments_count_and_progress(practice_env) -> None:
    http, sender, agent, _ = practice_env
    headers, tree_id, _ = await create_two_words(http, sender, agent)

    response = await http.post(
        f"/api/v1/practice/{tree_id}/complete",
        headers=headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["practice_count"] == 1
    assert response.json()["last_practiced_at"]

    response = await http.post(
        f"/api/v1/practice/{tree_id}/complete",
        headers=headers,
    )
    assert response.json()["practice_count"] == 2

    response = await http.get("/api/v1/progress", headers=headers)
    assert response.json()["practices"] == 2


@pytest.mark.asyncio
async def test_complete_rejects_unknown_word(practice_env) -> None:
    http, sender, agent, _ = practice_env
    headers, _, _ = await create_two_words(http, sender, agent)

    response = await http.post(
        "/api/v1/practice/missing/complete",
        headers=headers,
    )
    assert response.status_code == 404, response.text
    assert response.json()["code"] == "word_not_found"


@pytest.mark.asyncio
async def test_next_without_saved_words_returns_stable_error(practice_env) -> None:
    http, sender, _, _ = practice_env
    verified = await request_and_verify(http, sender, "empty-practice@example.com")
    headers = bearer(verified["session_token"])

    response = await http.get("/api/v1/practice/next", headers=headers)
    assert response.status_code == 404, response.text
    assert response.json()["code"] == "practice_no_words"


@pytest.mark.asyncio
async def test_reply_returns_recast_and_passes_word_context(practice_env) -> None:
    http, sender, agent, practice_agent = practice_env
    headers, tree_id, _ = await create_two_words(http, sender, agent)

    response = await http.post(
        f"/api/v1/practice/{tree_id}/reply",
        headers=headers,
        json={
            "text": "I saw a tree in the park.",
            "history": [{"role": "learner", "text": "Hello"}],
        },
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["reply"] == "How often do you see a tree?"
    assert body["recast"] == "I saw a tree yesterday."
    assert practice_agent.calls[0]["word"] == "tree"
    assert practice_agent.calls[0]["context"] == "I saw a tree today."
    assert practice_agent.calls[0]["history"] == [{"role": "learner", "text": "Hello"}]


@pytest.mark.asyncio
async def test_reply_rejects_unknown_word(practice_env) -> None:
    http, sender, agent, _ = practice_env
    headers, _, _ = await create_two_words(http, sender, agent)

    response = await http.post(
        "/api/v1/practice/missing/reply",
        headers=headers,
        json={"text": "Hello"},
    )
    assert response.status_code == 404, response.text
    assert response.json()["code"] == "word_not_found"


@pytest.mark.asyncio
async def test_reply_maps_agent_failure(practice_env) -> None:
    http, sender, agent, practice_agent = practice_env
    headers, tree_id, _ = await create_two_words(http, sender, agent)
    practice_agent.fail = True

    response = await http.post(
        f"/api/v1/practice/{tree_id}/reply",
        headers=headers,
        json={"text": "Hello"},
    )
    assert response.status_code == 502, response.text
    assert response.json()["code"] == "practice_agent_failed"
