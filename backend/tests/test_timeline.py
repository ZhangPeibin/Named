import asyncio

import pytest
import pytest_asyncio
from test_discovery import (
    FakeDiscoveryAgent,
    FakeTTSProvider,
    bearer,
    request_and_verify,
    scene_output,
    word_output,
)
from test_talk import FakeTalkAgent, create_conversation, create_word, talk_client


@pytest_asyncio.fixture
async def timeline_env(tmp_path):
    discovery_agent = FakeDiscoveryAgent()
    talk_agent = FakeTalkAgent()
    tts = FakeTTSProvider()
    async with talk_client(discovery_agent, talk_agent, tts, str(tmp_path)) as (
        http,
        sender,
        sessions,
    ):
        yield http, sender, sessions, discovery_agent, talk_agent


def auth_headers(verified: dict) -> dict[str, str]:
    return bearer(verified["session_token"])


@pytest.mark.asyncio
async def test_timeline_returns_word_and_talk_items(timeline_env) -> None:
    http, sender, _, _, _ = timeline_env
    verified, headers, word_id = await create_word(http, sender, "timeline@example.com")

    response = await http.get("/api/v1/timeline", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert len(body["items"]) == 1
    word_item = body["items"][0]
    assert word_item["type"] == "word"
    assert word_item["input_text"] == "树"
    assert word_item["word"]["spelling"] == "tree"
    assert word_item["conversation_id"] is None
    assert word_item["word"]["grammar"]

    conversation_id = await create_conversation(http, headers, word_id)
    response = await http.get("/api/v1/timeline", headers=headers)
    word_item = response.json()["items"][0]
    assert word_item["conversation_id"] == conversation_id

    await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"client_message_id": "timeline-1", "text": "I saw a tree."},
    )
    response = await http.get("/api/v1/timeline", headers=headers)
    items = response.json()["items"]
    assert [item["type"] for item in items] == ["talk", "word"]
    talk_item = items[0]
    assert talk_item["conversation_id"] == conversation_id
    assert talk_item["title"] == "tree"
    assert talk_item["message_count"] == 2
    assert talk_item["last_message"]["text"].startswith("That sounds lovely")
    assert body["next_cursor"] is None


@pytest.mark.asyncio
async def test_timeline_type_filter_and_cursor(timeline_env) -> None:
    http, sender, _, discovery_agent, _ = timeline_env
    _, headers, _ = await create_word(http, sender, "filter@example.com")
    await asyncio.sleep(0.02)
    discovery_agent.output = word_output("flower")
    await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "花"},
    )

    first = await http.get("/api/v1/timeline", headers=headers, params={"limit": 1})
    assert first.status_code == 200, first.text
    first_body = first.json()
    assert len(first_body["items"]) == 1
    assert first_body["items"][0]["word"]["spelling"] == "flower"
    assert first_body["next_cursor"] is not None

    second = await http.get(
        "/api/v1/timeline",
        headers=headers,
        params={"limit": 1, "before": first_body["next_cursor"]},
    )
    assert second.status_code == 200, second.text
    assert second.json()["items"][0]["word"]["spelling"] == "tree"

    words = await http.get(
        "/api/v1/timeline",
        headers=headers,
        params={"type": "word"},
    )
    assert all(item["type"] == "word" for item in words.json()["items"])

    talks = await http.get(
        "/api/v1/timeline",
        headers=headers,
        params={"type": "talk"},
    )
    assert talks.json()["items"] == []


@pytest.mark.asyncio
async def test_timeline_is_scoped_to_account(timeline_env) -> None:
    http, sender, _, _, _ = timeline_env
    await create_word(http, sender, "owner@example.com")
    other = await request_and_verify(http, sender, "other@example.com")

    response = await http.get(
        "/api/v1/timeline",
        headers=auth_headers(other),
    )
    assert response.status_code == 200
    assert response.json()["items"] == []


@pytest.mark.asyncio
async def test_timeline_rejects_invalid_cursor(timeline_env) -> None:
    http, sender, _, _, _ = timeline_env
    _, headers, _ = await create_word(http, sender, "cursor@example.com")

    response = await http.get(
        "/api/v1/timeline",
        headers=headers,
        params={"before": "not-a-date"},
    )
    assert response.status_code == 400
    assert response.json()["code"] == "invalid_cursor"


@pytest.mark.asyncio
async def test_timeline_returns_scene_items(timeline_env) -> None:
    http, sender, _, discovery_agent, _ = timeline_env
    discovery_agent.output = scene_output()
    verified = await request_and_verify(http, sender, "scene-timeline@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "今天在公园里和女儿休息了一会儿"},
    )
    assert response.status_code == 201
    discovery_id = response.json()["id"]

    response = await http.get("/api/v1/timeline", headers=headers)
    assert response.status_code == 200, response.text
    items = response.json()["items"]
    assert len(items) == 1
    scene_item = items[0]
    assert scene_item["type"] == "scene"
    assert scene_item["input_text"] == "今天在公园里和女儿休息了一会儿"
    assert scene_item["scene"]["natural_english"] == ("I rested in the park with my daughter.")
    assert scene_item["audio"]["status"] == "ready"
    assert scene_item["conversation_id"] is None

    conversation = await http.post(
        "/api/v1/conversations",
        headers=headers,
        json={"focus_type": "scene", "focus_id": discovery_id},
    )
    assert conversation.status_code == 201
    conversation_id = conversation.json()["id"]

    response = await http.get("/api/v1/timeline", headers=headers)
    scene_item = response.json()["items"][0]
    assert scene_item["conversation_id"] == conversation_id
