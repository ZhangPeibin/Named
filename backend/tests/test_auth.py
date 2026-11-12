import logging
from contextlib import asynccontextmanager
from datetime import timedelta

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from clock import utcnow
from config import Settings, get_settings
from database import get_session
from lifecycle import purge_expired_deletions
from mailer import get_email_sender
from main import app
from models import (
    Account,
    AuthCode,
    AuthSession,
    Base,
    Challenge,
    ChallengeItem,
    Conversation,
    ConversationMessage,
    Discovery,
    ErrorPattern,
    Experience,
    ExperienceJob,
    ExperienceSource,
    MemoryItem,
    SoulItem,
    Word,
    WordProgress,
)


class FakeEmailSender:
    def __init__(self) -> None:
        self.messages: list[tuple[str, str]] = []

    async def send_code(self, email: str, code: str) -> None:
        self.messages.append((email, code))

    @property
    def latest_code(self) -> str:
        return self.messages[-1][1]


class FakeMediaStore:
    def __init__(self) -> None:
        self.deleted: list[str] = []

    async def put(self, key: str, data: bytes, content_type: str = "") -> None:
        return None

    async def get(self, key: str) -> bytes | None:
        return None

    async def exists(self, key: str) -> bool:
        return False

    async def delete(self, key: str) -> None:
        self.deleted.append(key)


@asynccontextmanager
async def auth_client(settings: Settings):
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

    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client, sender, session_factory
    finally:
        app.dependency_overrides.clear()
        await engine.dispose()


@pytest_asyncio.fixture
async def client():
    settings = Settings(
        auth_secret="test-secret",
        auth_code_resend_cooldown_seconds=0,
        auth_code_max_per_hour=1000,
    )
    async with auth_client(settings) as (http, sender, sessions):
        yield http, sender, sessions


async def request_and_verify(
    client,
    sender,
    email: str,
    initial_soul: dict | None = None,
) -> dict:
    response = await client.post("/api/v1/auth/code", json={"email": email})
    assert response.status_code == 202, response.text
    code = sender.latest_code

    response = await client.post(
        "/api/v1/auth/verify",
        json={
            "email": email,
            "code": code,
            "initial_soul": initial_soul or {"native_language": "zh"},
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def assert_problem(response, status_code: int, code: str, *, retry_after: bool = False) -> None:
    assert response.status_code == status_code, response.text
    assert response.headers["content-type"].startswith("application/problem+json")
    body = response.json()
    assert body["status"] == status_code
    assert body["code"] == code
    assert body["request_id"]
    assert response.headers["X-Request-ID"] == body["request_id"]
    if retry_after:
        assert int(response.headers["Retry-After"]) > 0


@pytest.mark.asyncio
async def test_new_user_can_request_code_and_verify(client) -> None:
    http, sender, _ = client

    response = await http.post(
        "/api/v1/auth/code",
        json={"email": "New.User@Example.com"},
    )
    assert response.status_code == 202
    assert response.json()["expires_in"] == 600
    assert response.json()["resend_after"] == 0
    assert len(sender.latest_code) == 6

    verified = await request_and_verify(http, sender, "New.User@Example.com")
    assert verified["is_new"] is True
    assert verified["account"]["email"] == "new.user@example.com"
    assert verified["soul"]["profile"]["native_language"] == "zh"
    assert verified["session_token"]

    me = await http.get("/api/v1/me", headers=bearer(verified["session_token"]))
    assert me.status_code == 200
    assert me.json()["email"] == "new.user@example.com"


@pytest.mark.asyncio
async def test_returning_user_restores_same_account(client) -> None:
    http, sender, _ = client

    first = await request_and_verify(http, sender, "returning@example.com")
    second = await request_and_verify(http, sender, "returning@example.com")

    assert first["is_new"] is True
    assert second["is_new"] is False
    assert first["account"]["id"] == second["account"]["id"]


@pytest.mark.asyncio
async def test_wrong_code_does_not_create_session(client) -> None:
    http, sender, _ = client

    response = await http.post("/api/v1/auth/code", json={"email": "wrong@example.com"})
    assert response.status_code == 202
    wrong_code = "000000" if sender.latest_code != "000000" else "111111"

    response = await http.post(
        "/api/v1/auth/verify",
        json={"email": "wrong@example.com", "code": wrong_code},
    )
    assert response.status_code == 400
    assert response.json()["code"] == "invalid_code"

    me = await http.get("/api/v1/me")
    assert me.status_code == 401


@pytest.mark.asyncio
async def test_code_cannot_be_reused(client) -> None:
    http, sender, _ = client

    response = await http.post("/api/v1/auth/code", json={"email": "reuse@example.com"})
    assert response.status_code == 202
    code = sender.latest_code

    first = await http.post(
        "/api/v1/auth/verify",
        json={
            "email": "reuse@example.com",
            "code": code,
            "initial_soul": {"native_language": "zh"},
        },
    )
    assert first.status_code == 200

    second = await http.post(
        "/api/v1/auth/verify",
        json={"email": "reuse@example.com", "code": code},
    )
    assert second.status_code == 400


@pytest.mark.asyncio
async def test_expired_code_is_rejected(client) -> None:
    http, sender, session_factory = client

    response = await http.post("/api/v1/auth/code", json={"email": "expired@example.com"})
    assert response.status_code == 202
    code = sender.latest_code

    async with session_factory() as session:
        auth_code = await session.scalar(
            select(AuthCode).where(AuthCode.email == "expired@example.com")
        )
        assert auth_code is not None
        auth_code.expires_at = utcnow() - timedelta(seconds=1)
        await session.commit()

    response = await http.post(
        "/api/v1/auth/verify",
        json={"email": "expired@example.com", "code": code},
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_logout_revokes_session(client) -> None:
    http, sender, _ = client
    verified = await request_and_verify(http, sender, "logout@example.com")
    token = verified["session_token"]

    response = await http.post("/api/v1/auth/logout", headers=bearer(token))
    assert response.status_code == 204

    me = await http.get("/api/v1/me", headers=bearer(token))
    assert me.status_code == 401


@pytest.mark.asyncio
async def test_accounts_are_isolated(client) -> None:
    http, sender, _ = client

    first = await request_and_verify(http, sender, "first@example.com")
    second = await request_and_verify(http, sender, "second@example.com")

    first_me = await http.get("/api/v1/me", headers=bearer(first["session_token"]))
    second_me = await http.get("/api/v1/me", headers=bearer(second["session_token"]))

    assert first_me.json()["email"] == "first@example.com"
    assert second_me.json()["email"] == "second@example.com"
    assert first_me.json()["id"] != second_me.json()["id"]


@pytest.mark.asyncio
async def test_invalid_email_is_rejected(client) -> None:
    http, _, _ = client

    response = await http.post("/api/v1/auth/code", json={"email": "not-an-email"})
    assert_problem(response, 422, "validation_error")


@pytest.mark.asyncio
async def test_resend_cooldown_returns_429() -> None:
    settings = Settings(
        auth_secret="test-secret",
        auth_code_resend_cooldown_seconds=60,
        auth_code_max_per_hour=1000,
    )
    async with auth_client(settings) as (http, _, _):
        first = await http.post("/api/v1/auth/code", json={"email": "cooldown@example.com"})
        assert first.status_code == 202

        second = await http.post("/api/v1/auth/code", json={"email": "cooldown@example.com"})
        assert_problem(second, 429, "rate_limited", retry_after=True)


@pytest.mark.asyncio
async def test_new_user_requires_initial_soul(client) -> None:
    http, sender, _ = client

    response = await http.post("/api/v1/auth/code", json={"email": "nosoul@example.com"})
    assert response.status_code == 202
    code = sender.latest_code

    response = await http.post(
        "/api/v1/auth/verify",
        json={"email": "nosoul@example.com", "code": code},
    )
    assert response.status_code == 400
    assert response.json()["code"] == "native_language_required"

    response = await http.post(
        "/api/v1/auth/verify",
        json={
            "email": "nosoul@example.com",
            "code": code,
            "initial_soul": {"native_language": "zh"},
        },
    )
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_returning_user_keeps_existing_soul(client) -> None:
    http, sender, _ = client

    first = await request_and_verify(
        http, sender, "returnsoul@example.com", {"native_language": "zh"}
    )
    second = await request_and_verify(
        http, sender, "returnsoul@example.com", {"native_language": "en"}
    )

    assert first["soul"]["profile"]["native_language"] == "zh"
    assert second["soul"]["profile"]["native_language"] == "zh"


@pytest.mark.asyncio
async def test_soul_can_be_viewed_and_updated(client) -> None:
    http, sender, _ = client
    verified = await request_and_verify(
        http,
        sender,
        "soul@example.com",
        {"native_language": "zh", "interests": ["gardening"]},
    )
    headers = bearer(verified["session_token"])

    response = await http.get("/api/v1/soul", headers=headers)
    assert response.status_code == 200
    soul = response.json()
    assert soul["profile"]["native_language"] == "zh"
    assert soul["items"][0]["text"] == "gardening"
    assert soul["items"][0]["source"] == "onboarding"

    response = await http.patch(
        "/api/v1/soul",
        headers=headers,
        json={"native_language": "en", "age": 30, "gender": "female"},
    )
    assert response.status_code == 200
    assert response.json()["profile"]["native_language"] == "en"
    assert response.json()["profile"]["age"] == 30

    response = await http.patch(
        "/api/v1/soul",
        headers=headers,
        json={"age": None, "gender": None},
    )
    assert response.status_code == 200
    assert response.json()["profile"]["age"] is None
    assert response.json()["profile"]["gender"] is None

    response = await http.post(
        "/api/v1/soul/items",
        headers=headers,
        json={"kind": "preference", "text": "short conversations"},
    )
    assert response.status_code == 201
    item = response.json()
    assert item["source"] == "user_edit"

    response = await http.patch(
        f"/api/v1/soul/items/{item['id']}",
        headers=headers,
        json={"text": "short daily conversations"},
    )
    assert response.status_code == 200
    assert response.json()["text"] == "short daily conversations"

    response = await http.delete(f"/api/v1/soul/items/{item['id']}", headers=headers)
    assert response.status_code == 204

    response = await http.get("/api/v1/soul", headers=headers)
    assert all(entry["id"] != item["id"] for entry in response.json()["items"])


@pytest.mark.asyncio
async def test_soul_is_isolated(client) -> None:
    http, sender, _ = client

    first = await request_and_verify(http, sender, "soul1@example.com")
    second = await request_and_verify(http, sender, "soul2@example.com")

    response = await http.post(
        "/api/v1/soul/items",
        headers=bearer(first["session_token"]),
        json={"kind": "interest", "text": "first only"},
    )
    assert response.status_code == 201
    item_id = response.json()["id"]

    response = await http.get("/api/v1/soul", headers=bearer(second["session_token"]))
    assert response.status_code == 200
    assert response.json()["items"] == []

    response = await http.delete(
        f"/api/v1/soul/items/{item_id}",
        headers=bearer(second["session_token"]),
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_soul_rejects_missing_native_language(client) -> None:
    http, sender, _ = client

    response = await http.post("/api/v1/auth/code", json={"email": "bad-soul@example.com"})
    assert response.status_code == 202
    code = sender.latest_code

    response = await http.post(
        "/api/v1/auth/verify",
        json={
            "email": "bad-soul@example.com",
            "code": code,
            "initial_soul": {"age": 30},
        },
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_soul_requires_auth(client) -> None:
    http, _, _ = client

    response = await http.get("/api/v1/soul")
    assert_problem(response, 401, "unauthorized")


@pytest.mark.asyncio
async def test_delete_account_schedules_and_blocks_login(client) -> None:
    http, sender, sessions = client
    verified = await request_and_verify(http, sender, "delete@example.com")
    token = verified["session_token"]
    account_id = verified["account"]["id"]

    response = await http.delete("/api/v1/me", headers=bearer(token))
    assert response.status_code == 202
    body = response.json()
    assert body["status"] == "deletion_scheduled"
    assert body["deletion_scheduled_at"]

    me = await http.get("/api/v1/me", headers=bearer(token))
    assert_problem(me, 401, "unauthorized")

    response = await http.post(
        "/api/v1/auth/code",
        json={"email": "delete@example.com"},
    )
    assert_problem(response, 403, "account_deleted")

    async with sessions() as session:
        account = await session.get(Account, account_id)
        assert account is not None
        assert account.deleted_at is not None
        rows = await session.scalars(
            select(AuthSession).where(AuthSession.account_id == account_id)
        )
        assert all(row.revoked_at is not None for row in rows)


@pytest.mark.asyncio
async def test_purge_expired_deletions_removes_data(client) -> None:
    http, sender, sessions = client
    verified = await request_and_verify(http, sender, "purge@example.com")
    token = verified["session_token"]
    account_id = verified["account"]["id"]

    async with sessions() as session:
        session.add(
            SoulItem(
                account_id=account_id,
                kind="interest",
                text="gardening",
                source="user_edit",
            )
        )
        word = Word(canonical_key="purge-tree", label_en="tree")
        session.add(word)
        await session.flush()
        progress = WordProgress(account_id=account_id, word_id=word.id)
        session.add(progress)
        discovery = Discovery(
            account_id=account_id,
            input_type="image",
            image_key="discovery-images/test.jpg",
            scene_audio_key="talk-audio/scene.mp3",
            status="ready",
        )
        session.add(discovery)
        conversation = Conversation(
            account_id=account_id,
            focus_type="word",
            focus_id="word-id",
            status="active",
        )
        session.add(conversation)
        await session.flush()
        session.add(
            MemoryItem(
                account_id=account_id,
                kind="experience",
                text="The learner grows mint.",
                canonical_key="purge-mint",
                source_type="conversation_message",
                source_id="purge-source",
            )
        )
        session.add(
            ErrorPattern(
                account_id=account_id,
                category="grammar",
                pattern_key="third_person_s",
                label="Third person -s",
            )
        )
        experience = Experience(
            account_id=account_id,
            conversation_id=conversation.id,
            kind="life",
            summary="A personal experience.",
            confidence=0.9,
        )
        session.add(experience)
        await session.flush()
        session.add(
            ExperienceSource(
                experience_id=experience.id,
                source_type="conversation",
                source_id=conversation.id,
            )
        )
        challenge = Challenge(
            account_id=account_id,
            name="Purge challenge",
            planned_days=2,
            status="active",
        )
        session.add(challenge)
        await session.flush()
        session.add(
            ChallengeItem(
                challenge_id=challenge.id,
                discovery_id=discovery.id,
                position=0,
            )
        )
        session.add(
            ExperienceJob(
                account_id=account_id,
                conversation_id=conversation.id,
                status="pending",
                attempts=0,
                available_at=utcnow(),
            )
        )
        await session.flush()
        discovery_id = discovery.id
        progress_id = progress.id
        word_id = word.id
        experience_id = experience.id
        conversation_id = conversation.id
        message = ConversationMessage(
            conversation_id=conversation_id,
            sequence=2,
            role="assistant",
            text="hello",
            source="text",
            transcript_state="confirmed",
            status="saved",
            audio_key="talk-audio/test.mp3",
        )
        session.add(message)
        await session.flush()
        message_id = message.id
        await session.commit()

    other = await request_and_verify(http, sender, "purge-other@example.com")
    other_account_id = other["account"]["id"]
    async with sessions() as session:
        session.add(WordProgress(account_id=other_account_id, word_id=word_id))
        session.add(
            MemoryItem(
                account_id=other_account_id,
                kind="experience",
                text="The other learner grows basil.",
                canonical_key="purge-other-basil",
                source_type="conversation_message",
                source_id="purge-other-source",
            )
        )
        await session.commit()

    response = await http.delete("/api/v1/me", headers=bearer(token))
    assert response.status_code == 202

    async with sessions() as session:
        account = await session.get(Account, account_id)
        assert account is not None
        account.deletion_scheduled_at = utcnow() - timedelta(days=1)
        await session.commit()

    store = FakeMediaStore()
    async with sessions() as session:
        purged = await purge_expired_deletions(session, store)
        assert await purge_expired_deletions(session, store) == 0

    assert purged == 1
    assert "discovery-images/test.jpg" in store.deleted
    assert "talk-audio/scene.mp3" in store.deleted
    assert "talk-audio/test.mp3" in store.deleted

    async with sessions() as session:
        assert await session.get(Account, account_id) is None
        assert await session.get(Discovery, discovery_id) is None
        assert await session.get(Conversation, conversation_id) is None
        assert await session.get(ConversationMessage, message_id) is None
        assert await session.get(Experience, experience_id) is None
        assert (
            await session.scalar(
                select(ExperienceSource).where(ExperienceSource.experience_id == experience_id)
            )
            is None
        )
        assert (
            await session.scalar(
                select(ExperienceJob).where(ExperienceJob.conversation_id == conversation_id)
            )
            is None
        )
        assert await session.get(WordProgress, progress_id) is None
        assert await session.get(Challenge, challenge.id) is None
        assert (
            await session.scalar(
                select(ChallengeItem).where(ChallengeItem.challenge_id == challenge.id)
            )
            is None
        )
        assert await session.get(Word, word_id) is not None
        assert await session.get(Account, other_account_id) is not None
        assert (
            await session.scalar(
                select(WordProgress).where(WordProgress.account_id == other_account_id)
            )
            is not None
        )
        assert (
            await session.scalar(
                select(MemoryItem).where(MemoryItem.account_id == other_account_id)
            )
            is not None
        )
        assert (
            await session.scalar(select(MemoryItem).where(MemoryItem.account_id == account_id))
            is None
        )
        assert (
            await session.scalar(select(ErrorPattern).where(ErrorPattern.account_id == account_id))
            is None
        )
        soul_items = await session.scalars(
            select(SoulItem).where(SoulItem.account_id == account_id)
        )
        assert list(soul_items) == []

    response = await http.post(
        "/api/v1/auth/code",
        json={"email": "purge@example.com"},
    )
    assert response.status_code == 202
    reverified = await request_and_verify(http, sender, "purge@example.com")
    assert reverified["is_new"] is True


@pytest.mark.asyncio
async def test_missing_soul_item_returns_problem_json(client) -> None:
    http, sender, _ = client
    verified = await request_and_verify(http, sender, "contract@example.com")
    headers = bearer(verified["session_token"])

    response = await http.patch(
        "/api/v1/soul/items/does-not-exist",
        headers=headers,
        json={"text": "updated"},
    )
    assert_problem(response, 404, "soul_item_not_found")


@pytest.mark.asyncio
async def test_logs_do_not_contain_tokens_or_codes(client, caplog) -> None:
    http, sender, _ = client
    caplog.set_level(logging.INFO)

    response = await http.post("/api/v1/auth/code", json={"email": "logs@example.com"})
    assert response.status_code == 202
    code = sender.latest_code
    verified = await request_and_verify(http, sender, "logs@example.com")
    token = verified["session_token"]

    assert code not in caplog.text
    assert token not in caplog.text


@pytest.mark.asyncio
async def test_openapi_and_problem_json(client) -> None:
    http, _, _ = client

    response = await http.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/auth/code" in paths
    assert "/api/v1/conversations/{conversation_id}/messages" in paths

    live = await http.get("/health/live")
    assert live.status_code == 200
    assert live.headers["X-Request-ID"]

    invalid = await http.post("/api/v1/auth/code", json={"email": "not-an-email"})
    assert invalid.status_code == 422
    assert invalid.headers["content-type"].startswith("application/problem+json")
    assert invalid.json()["code"] == "validation_error"
    assert invalid.json()["request_id"]
