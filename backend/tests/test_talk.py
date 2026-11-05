from contextlib import asynccontextmanager

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool
from test_discovery import (
    FakeDiscoveryAgent,
    FakeEmailSender,
    FakeTTSProvider,
    bearer,
    png_bytes,
    request_and_verify,
    scene_output,
)

from config import Settings, get_settings
from database import get_session
from discovery.agent import get_discovery_agent
from mailer import get_email_sender
from main import app
from models import Base
from talk.agent import AgentFailed, get_talk_agent
from talk.schemas import Annotation, Correction, TalkResponse
from tts.provider import get_tts_provider


class FakeTalkAgent:
    def __init__(self) -> None:
        self.calls: list[dict] = []
        self.fail = False
        self.response = TalkResponse(
            reply="That sounds lovely. How do you take care of it?",
            corrections=[
                Correction(
                    original="I am grow mint on my balcony.",
                    suggestion="I am growing mint on my balcony.",
                    note="用现在进行时描述正在进行的动作。",
                )
            ],
            annotations=[
                Annotation(
                    text="growing",
                    kind="word",
                    meaning_zh="种植；生长",
                )
            ],
            suggested_expressions=["I am growing mint on my balcony."],
        )

    async def respond(
        self,
        *,
        native_language: str,
        focus_context: str,
        soul_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> TalkResponse:
        self.calls.append(
            {
                "native_language": native_language,
                "focus_context": focus_context,
                "soul_context": soul_context,
                "history": history,
                "user_text": user_text,
            }
        )
        if self.fail:
            raise AgentFailed("provider failed")
        return self.response


@asynccontextmanager
async def talk_client(
    discovery_agent: FakeDiscoveryAgent,
    talk_agent: FakeTalkAgent,
    tts: FakeTTSProvider,
    media_root: str,
    talk_limit: int = 1000,
    discover_limit: int = 1000,
):
    settings = Settings(
        auth_secret="test-secret",
        auth_code_resend_cooldown_seconds=0,
        auth_code_max_per_hour=1000,
        ai_model="deepseek:deepseek-flash",
        ai_prompt_version="discover-v1",
        tts_model="qwen-audio-3.1-tts-plus",
        tts_voice_us="longanfengyue_v3.1",
        tts_voice_uk="longanfengyue_v3.1",
        tts_voice_talk="longanfengyue_v3.1",
        tts_format="mp3",
        tts_rate=1.0,
        talk_audio_ttl_seconds=604800,
        media_root=media_root,
        media_url_prefix="/api/v1/audio",
        rate_limit_talk_per_minute=talk_limit,
        rate_limit_discover_per_minute=discover_limit,
    )
    engine = create_async_engine(
        "sqlite+aiosqlite://",
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    async def override_session():
        async with session_factory() as session:
            yield session

    sender = FakeEmailSender()
    app.dependency_overrides[get_session] = override_session
    app.dependency_overrides[get_email_sender] = lambda: sender
    app.dependency_overrides[get_settings] = lambda: settings
    app.dependency_overrides[get_discovery_agent] = lambda: discovery_agent
    app.dependency_overrides[get_talk_agent] = lambda: talk_agent
    app.dependency_overrides[get_tts_provider] = lambda: tts

    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client, sender, session_factory
    finally:
        app.dependency_overrides.clear()
        await engine.dispose()


@pytest_asyncio.fixture
async def talk_env(tmp_path):
    discovery_agent = FakeDiscoveryAgent()
    talk_agent = FakeTalkAgent()
    tts = FakeTTSProvider()
    async with talk_client(discovery_agent, talk_agent, tts, str(tmp_path)) as (
        http,
        sender,
        sessions,
    ):
        yield http, sender, sessions, discovery_agent, talk_agent, tts


async def create_word(http, sender, email: str) -> tuple[dict, dict[str, str], str]:
    verified = await request_and_verify(http, sender, email)
    headers = bearer(verified["session_token"])
    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert response.status_code == 201, response.text
    return verified, headers, response.json()["word_id"]


async def create_conversation(http, headers, word_id: str) -> str:
    response = await http.post(
        "/api/v1/conversations",
        headers=headers,
        json={"focus_type": "word", "focus_id": word_id},
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


@pytest.mark.asyncio
async def test_create_conversation_and_send_message(talk_env) -> None:
    http, sender, _, _, agent, _ = talk_env
    _, headers, word_id = await create_word(http, sender, "talk@example.com")
    conversation_id = await create_conversation(http, headers, word_id)

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={
            "client_message_id": "m1",
            "text": "I am grow mint on my balcony.",
        },
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["save_status"] == "saved"
    assert body["user_message"]["text"] == "I am grow mint on my balcony."
    assert body["assistant_message"]["text"].startswith("That sounds lovely")
    assert body["user_message"]["corrections"][0]["suggestion"] == (
        "I am growing mint on my balcony."
    )
    assert body["assistant_message"]["annotations"][0]["text"] == "growing"
    assert body["assistant_message"]["audio"]["status"] == "ready"
    assert agent.calls[-1]["native_language"] == "zh"
    assert "tree" in agent.calls[-1]["focus_context"]

    detail = await http.get(
        f"/api/v1/conversations/{conversation_id}",
        headers=headers,
    )
    assert detail.status_code == 200
    assert len(detail.json()["messages"]) == 2


@pytest.mark.asyncio
async def test_message_idempotency(talk_env) -> None:
    http, sender, _, _, _, _ = talk_env
    _, headers, word_id = await create_word(http, sender, "idempotent@example.com")
    conversation_id = await create_conversation(http, headers, word_id)
    payload = {
        "client_message_id": "same-message",
        "text": "I am growing mint on my balcony.",
    }

    first = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json=payload,
    )
    second = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json=payload,
    )

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["assistant_message"]["id"] == second.json()["assistant_message"]["id"]

    detail = await http.get(
        f"/api/v1/conversations/{conversation_id}",
        headers=headers,
    )
    assert len(detail.json()["messages"]) == 2


@pytest.mark.asyncio
async def test_agent_failure_then_retry(talk_env) -> None:
    http, sender, _, _, agent, _ = talk_env
    _, headers, word_id = await create_word(http, sender, "retry@example.com")
    conversation_id = await create_conversation(http, headers, word_id)
    payload = {"client_message_id": "retry-message", "text": "I like this tree."}

    agent.fail = True
    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json=payload,
    )
    assert response.status_code == 502

    detail = await http.get(
        f"/api/v1/conversations/{conversation_id}",
        headers=headers,
    )
    messages = detail.json()["messages"]
    assert len(messages) == 1
    assert messages[0]["role"] == "user"
    user_id = messages[0]["id"]

    agent.fail = False
    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json=payload,
    )
    assert response.status_code == 200, response.text
    assert response.json()["user_message"]["id"] == user_id

    detail = await http.get(
        f"/api/v1/conversations/{conversation_id}",
        headers=headers,
    )
    assert len(detail.json()["messages"]) == 2


@pytest.mark.asyncio
async def test_tts_failure_does_not_block_reply(talk_env) -> None:
    http, sender, _, _, _, tts = talk_env
    _, headers, word_id = await create_word(http, sender, "talk-tts-fail@example.com")
    conversation_id = await create_conversation(http, headers, word_id)
    tts.fail = True

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"client_message_id": "tts-fail", "text": "I like this tree."},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["assistant_message"]["text"]
    assert body["assistant_message"]["audio"] is None


@pytest.mark.asyncio
async def test_voice_transcript_must_be_confirmed(talk_env) -> None:
    http, sender, _, _, _, _ = talk_env
    _, headers, word_id = await create_word(http, sender, "voice@example.com")
    conversation_id = await create_conversation(http, headers, word_id)

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={
            "client_message_id": "voice-1",
            "text": "I like this tree.",
            "source": "voice",
            "transcript_confirmed": False,
        },
    )
    assert response.status_code == 400
    assert response.json()["code"] == "transcript_unconfirmed"

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={
            "client_message_id": "voice-2",
            "text": "I like this tree.",
            "source": "voice",
            "transcript_confirmed": True,
        },
    )
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_conversation_is_isolated(talk_env) -> None:
    http, sender, _, _, _, _ = talk_env
    _, first_headers, word_id = await create_word(http, sender, "owner@example.com")
    conversation_id = await create_conversation(http, first_headers, word_id)
    second = await request_and_verify(http, sender, "intruder@example.com")
    second_headers = bearer(second["session_token"])

    response = await http.get(
        f"/api/v1/conversations/{conversation_id}",
        headers=second_headers,
    )
    assert response.status_code == 404

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=second_headers,
        json={"client_message_id": "intruder", "text": "Hello."},
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_ended_conversation_rejects_messages(talk_env) -> None:
    http, sender, _, _, _, _ = talk_env
    _, headers, word_id = await create_word(http, sender, "ended@example.com")
    conversation_id = await create_conversation(http, headers, word_id)

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/end",
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json()["status"] == "ended"

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"client_message_id": "after-end", "text": "Still there?"},
    )
    assert response.status_code == 409
    assert response.json()["code"] == "conversation_ended"


@pytest.mark.asyncio
async def test_scene_conversation_uses_scene_context(talk_env) -> None:
    http, sender, _, discovery_agent, talk_agent, _ = talk_env
    discovery_agent.output = scene_output()
    verified = await request_and_verify(http, sender, "scene-talk@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "今天在公园里和女儿休息了一会儿"},
    )
    assert response.status_code == 201
    discovery_id = response.json()["id"]

    response = await http.post(
        f"/api/v1/discoveries/{discovery_id}/focus",
        headers=headers,
        json={"whole_scene": True},
    )
    assert response.status_code == 200

    response = await http.post(
        "/api/v1/conversations",
        headers=headers,
        json={"focus_type": "scene", "focus_id": discovery_id},
    )
    assert response.status_code == 201
    conversation_id = response.json()["id"]

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"client_message_id": "scene-message", "text": "I sat under the tree."},
    )
    assert response.status_code == 200, response.text
    assert "Scene focus" in talk_agent.calls[-1]["focus_context"]


@pytest.mark.asyncio
async def test_create_conversation_requires_owned_focus(talk_env) -> None:
    http, sender, _, _, _, _ = talk_env
    _, first_headers, word_id = await create_word(http, sender, "focus-owner@example.com")
    second = await request_and_verify(http, sender, "focus-other@example.com")
    second_headers = bearer(second["session_token"])

    response = await http.post(
        "/api/v1/conversations",
        headers=second_headers,
        json={"focus_type": "word", "focus_id": word_id},
    )
    assert response.status_code == 404
    assert response.json()["code"] == "focus_not_found"


@pytest.mark.asyncio
async def test_talk_rate_limit(tmp_path) -> None:
    discovery_agent = FakeDiscoveryAgent()
    talk_agent = FakeTalkAgent()
    tts = FakeTTSProvider()
    async with talk_client(
        discovery_agent,
        talk_agent,
        tts,
        str(tmp_path),
        talk_limit=1,
    ) as (http, sender, _):
        _, headers, word_id = await create_word(http, sender, "rate-talk@example.com")
        conversation_id = await create_conversation(http, headers, word_id)

        first = await http.post(
            f"/api/v1/conversations/{conversation_id}/messages",
            headers=headers,
            json={"client_message_id": "rate-1", "text": "Hello."},
        )
        assert first.status_code == 200

        second = await http.post(
            f"/api/v1/conversations/{conversation_id}/messages",
            headers=headers,
            json={"client_message_id": "rate-2", "text": "Hello again."},
        )
        assert second.status_code == 429
        assert second.headers["Retry-After"]
        assert second.json()["code"] == "rate_limited"


@pytest.mark.asyncio
async def test_p0_end_to_end_journey(talk_env) -> None:
    http, sender, _, _, _, _ = talk_env
    verified = await request_and_verify(http, sender, "journey@example.com")
    headers = bearer(verified["session_token"])
    assert (await http.get("/health/live")).headers["X-Request-ID"]

    response = await http.patch(
        "/api/v1/soul",
        headers=headers,
        json={"native_language": "en"},
    )
    assert response.status_code == 200

    response = await http.post(
        "/api/v1/soul/items",
        headers=headers,
        json={"kind": "interest", "text": "gardening"},
    )
    assert response.status_code == 201

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert response.status_code == 201
    word_id = response.json()["word_id"]
    assert response.json()["audio"]["us"]["status"] == "ready"

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        files={"image": ("tree.png", png_bytes(), "image/png")},
        data={"text": "树"},
    )
    assert response.status_code == 201
    image_url = response.json()["image_url"]
    assert image_url

    image = await http.get(image_url, headers=headers)
    assert image.status_code == 200

    response = await http.post(
        "/api/v1/conversations",
        headers=headers,
        json={"focus_type": "word", "focus_id": word_id},
    )
    assert response.status_code == 201
    conversation_id = response.json()["id"]

    response = await http.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"client_message_id": "journey-1", "text": "I like this tree."},
    )
    assert response.status_code == 200
    assert response.json()["assistant_message"]["audio"]["status"] == "ready"

    response = await http.get(
        f"/api/v1/conversations/{conversation_id}",
        headers=headers,
    )
    assert response.status_code == 200
    assert len(response.json()["messages"]) == 2

    response = await http.delete("/api/v1/me", headers=headers)
    assert response.status_code == 202

    response = await http.get("/api/v1/me", headers=headers)
    assert response.status_code == 401
    assert response.headers["content-type"].startswith("application/problem+json")
    assert response.json()["code"] == "unauthorized"
