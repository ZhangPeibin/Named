from contextlib import asynccontextmanager

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool
from test_discovery import FakeEmailSender, bearer, request_and_verify

from agents import AgentFailed
from companion.moderation import BLOCKED_TERMS, RESERVED_NAMES
from companion.presence_agent import PresenceContext, get_presence_agent
from companion.service import RANDOM_NAMES
from config import Settings, get_settings
from database import get_session
from mailer import get_email_sender
from main import app
from models import Base


@asynccontextmanager
async def companion_client():
    settings = Settings(
        auth_secret="test-secret",
        auth_code_resend_cooldown_seconds=0,
        auth_code_max_per_hour=1000,
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
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app),
            base_url="http://test",
        ) as client:
            yield client, sender
    finally:
        app.dependency_overrides.clear()
        await engine.dispose()


@pytest_asyncio.fixture
async def companion_env():
    async with companion_client() as env:
        yield env


class FakePresenceAgent:
    def __init__(self) -> None:
        self.calls = 0
        self.fail = False
        self.context = PresenceContext()

    async def analyze(self, **kwargs) -> PresenceContext:
        self.calls += 1
        if self.fail:
            raise AgentFailed("failed")
        return self.context


async def signed_in(http, sender, email: str = "companion@example.com") -> dict[str, str]:
    verified = await request_and_verify(http, sender, email)
    return bearer(verified["session_token"])


@pytest.mark.asyncio
async def test_companion_is_created_unamed(companion_env) -> None:
    http, sender = companion_env
    headers = await signed_in(http, sender)

    response = await http.get("/api/v1/companion", headers=headers)

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["name"] is None
    assert body["gender"] is None
    assert body["hobby"] is None
    assert body["setup_dismissed"] is False
    assert body["avatar_key"] == "companion_chill"
    assert body["voice_key"] == "companion_default"


@pytest.mark.asyncio
async def test_update_companion(companion_env) -> None:
    http, sender = companion_env
    headers = await signed_in(http, sender)

    response = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"name": "Pip", "gender": "female", "hobby": "watching clouds"},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["name"] == "Pip"
    assert body["gender"] == "female"
    assert body["hobby"] == "watching clouds"

    fetched = await http.get("/api/v1/companion", headers=headers)
    assert fetched.json()["name"] == "Pip"


@pytest.mark.asyncio
async def test_name_suggestion_and_random_assignment(companion_env) -> None:
    http, sender = companion_env
    headers = await signed_in(http, sender)

    suggestion = await http.get("/api/v1/companion/name-suggestion", headers=headers)
    assert suggestion.status_code == 200, suggestion.text
    assert suggestion.json()["name"] in RANDOM_NAMES

    assigned = await http.post("/api/v1/companion/random-name", headers=headers)
    assert assigned.status_code == 200, assigned.text
    assert assigned.json()["name"] in RANDOM_NAMES

    fetched = await http.get("/api/v1/companion", headers=headers)
    assert fetched.json()["name"] == assigned.json()["name"]


@pytest.mark.asyncio
async def test_dismissal_is_persisted(companion_env) -> None:
    http, sender = companion_env
    headers = await signed_in(http, sender)

    dismissed = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"setup_dismissed": True},
    )
    assert dismissed.status_code == 200, dismissed.text
    assert dismissed.json()["setup_dismissed"] is True

    fetched = await http.get("/api/v1/companion", headers=headers)
    assert fetched.json()["setup_dismissed"] is True

    restored = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"setup_dismissed": False},
    )
    assert restored.json()["setup_dismissed"] is False


@pytest.mark.asyncio
async def test_invalid_companion_inputs(companion_env) -> None:
    http, sender = companion_env
    headers = await signed_in(http, sender)

    empty = await http.patch("/api/v1/companion", headers=headers, json={"name": "   "})
    assert empty.status_code == 400
    assert empty.json()["code"] == "companion_name_required"

    too_long = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"name": "abcdefghijklmnopq"},
    )
    assert too_long.status_code == 400
    assert too_long.json()["code"] == "companion_name_too_long"

    hobby_too_long = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"hobby": "a" * 25},
    )
    assert hobby_too_long.status_code == 400
    assert hobby_too_long.json()["code"] == "companion_hobby_too_long"

    bad_gender = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"gender": "robot"},
    )
    assert bad_gender.status_code == 422


@pytest.mark.asyncio
async def test_blocked_companion_inputs(companion_env) -> None:
    http, sender = companion_env
    headers = await signed_in(http, sender)

    reserved = next(iter(RESERVED_NAMES))
    blocked_name = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"name": reserved},
    )
    assert blocked_name.status_code == 400
    assert blocked_name.json()["code"] == "companion_name_rejected"

    blocked_hobby = await http.patch(
        "/api/v1/companion",
        headers=headers,
        json={"hobby": next(iter(BLOCKED_TERMS))},
    )
    assert blocked_hobby.status_code == 400
    assert blocked_hobby.json()["code"] == "companion_hobby_rejected"


@pytest.mark.asyncio
async def test_presence_uses_time_bucket_and_cache(companion_env) -> None:
    http, sender = companion_env
    headers = await signed_in(http, sender)
    agent = FakePresenceAgent()
    app.dependency_overrides[get_presence_agent] = lambda: agent
    try:
        first = await http.get(
            "/api/v1/companion/presence?local_hour=7",
            headers=headers,
        )
        assert first.status_code == 200, first.text
        body = first.json()
        assert body["key"] == "morning"
        assert 0 <= body["variant"] <= 2

        second = await http.get(
            "/api/v1/companion/presence?local_hour=7",
            headers=headers,
        )
        assert second.status_code == 200
        assert second.json() == body
        assert agent.calls == 1

        invalid = await http.get(
            "/api/v1/companion/presence?local_hour=25",
            headers=headers,
        )
        assert invalid.status_code == 422

        other = await signed_in(http, sender, "presence@example.com")
        agent.fail = True
        fallback = await http.get(
            "/api/v1/companion/presence?local_hour=7",
            headers=other,
        )
        assert fallback.status_code == 200, fallback.text
        assert fallback.json()["key"] == "morning"
    finally:
        app.dependency_overrides.pop(get_presence_agent, None)


@pytest.mark.asyncio
async def test_companions_are_account_scoped(companion_env) -> None:
    http, sender = companion_env
    first = await signed_in(http, sender, "first@example.com")
    second = await signed_in(http, sender, "second@example.com")

    await http.patch("/api/v1/companion", headers=first, json={"name": "Pip"})
    await http.patch("/api/v1/companion", headers=second, json={"name": "Moss"})

    assert (await http.get("/api/v1/companion", headers=first)).json()["name"] == "Pip"
    assert (await http.get("/api/v1/companion", headers=second)).json()["name"] == "Moss"
