import pytest
import pytest_asyncio
from test_discovery import FakeDiscoveryAgent, FakeTTSProvider
from test_talk import FakeTalkAgent, create_conversation, create_word, talk_client


@pytest_asyncio.fixture
async def progress_env(tmp_path):
    async with talk_client(
        FakeDiscoveryAgent(),
        FakeTalkAgent(),
        FakeTTSProvider(),
        str(tmp_path),
    ) as (http, sender, _):
        yield http, sender


@pytest.mark.asyncio
async def test_progress_counts_words_and_conversations(progress_env) -> None:
    http, sender = progress_env
    _, headers, word_id = await create_word(http, sender, "progress@example.com")

    response = await http.get("/api/v1/progress", headers=headers)
    assert response.status_code == 200, response.text
    assert response.json() == {"words": 1, "conversations": 0, "readings": 0}

    conversation_id = await create_conversation(http, headers, word_id)
    response = await http.get("/api/v1/progress", headers=headers)
    assert response.json()["conversations"] == 0

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"client_message_id": "progress-1", "text": "I saw a tree."},
    )
    assert response.status_code == 200, response.text

    response = await http.get("/api/v1/progress", headers=headers)
    assert response.json() == {"words": 1, "conversations": 1, "readings": 0}
