from contextlib import asynccontextmanager

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from assistant.agent import AgentFailed, get_intent_agent
from assistant.schemas import AssistantIntentOut
from config import Settings, get_settings
from database import get_session
from mailer import get_email_sender
from main import app
from models import Base


class FakeEmailSender:
    def __init__(self) -> None:
        self.messages: list[tuple[str, str]] = []

    async def send_code(self, email: str, code: str) -> None:
        self.messages.append((email, code))

    @property
    def latest_code(self) -> str:
        return self.messages[-1][1]


class FakeIntentAgent:
    def __init__(self, intent: str = "review_words") -> None:
        self.intent = intent
        self.calls: list[str] = []
        self.fail = False

    async def route(self, text: str) -> AssistantIntentOut:
        self.calls.append(text)
        if self.fail:
            raise AgentFailed("provider failed")
        return AssistantIntentOut(intent=self.intent, confidence=0.94)


@asynccontextmanager
async def assistant_client(agent: FakeIntentAgent):
    settings = Settings(
        auth_secret="test-secret",
        auth_code_resend_cooldown_seconds=0,
        auth_code_max_per_hour=1000,
        ai_model="deepseek:deepseek-flash",
        rate_limit_discover_per_minute=1000,
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
    app.dependency_overrides[get_intent_agent] = lambda: agent

    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client, sender
    finally:
        app.dependency_overrides.clear()
        await engine.dispose()


@pytest_asyncio.fixture
async def assistant_env():
    agent = FakeIntentAgent()
    async with assistant_client(agent) as (client, sender):
        yield client, sender, agent


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


async def request_and_verify(client, sender, email: str = "intent@example.com") -> dict:
    response = await client.post("/api/v1/auth/code", json={"email": email})
    assert response.status_code == 202, response.text
    response = await client.post(
        "/api/v1/auth/verify",
        json={
            "email": email,
            "code": sender.latest_code,
            "initial_soul": {"native_language": "zh"},
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


@pytest.mark.asyncio
async def test_route_returns_ai_intent(assistant_env) -> None:
    http, sender, agent = assistant_env
    agent.intent = "start_challenge"
    verified = await request_and_verify(http, sender)

    response = await http.post(
        "/api/v1/assistant/route",
        headers=bearer(verified["session_token"]),
        json={"text": "开始一个 challenge"},
    )

    assert response.status_code == 200, response.text
    assert response.json() == {"intent": "start_challenge", "confidence": 0.94}
    assert agent.calls == ["开始一个 challenge"]


@pytest.mark.asyncio
async def test_route_passes_normal_content_through(assistant_env) -> None:
    http, sender, agent = assistant_env
    agent.intent = "none"
    verified = await request_and_verify(http, sender, "normal@example.com")

    response = await http.post(
        "/api/v1/assistant/route",
        headers=bearer(verified["session_token"]),
        json={"text": "昨天我在公园里看到一棵树"},
    )

    assert response.status_code == 200
    assert response.json()["intent"] == "none"
    assert agent.calls == ["昨天我在公园里看到一棵树"]


@pytest.mark.asyncio
async def test_route_requires_auth(assistant_env) -> None:
    http, _, _ = assistant_env

    response = await http.post(
        "/api/v1/assistant/route",
        json={"text": "review words"},
    )

    assert response.status_code == 401


@pytest.mark.asyncio
async def test_route_rejects_empty_text(assistant_env) -> None:
    http, sender, _ = assistant_env
    verified = await request_and_verify(http, sender, "empty@example.com")

    response = await http.post(
        "/api/v1/assistant/route",
        headers=bearer(verified["session_token"]),
        json={"text": ""},
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_route_maps_agent_failure(assistant_env) -> None:
    http, sender, agent = assistant_env
    agent.fail = True
    verified = await request_and_verify(http, sender, "failure@example.com")

    response = await http.post(
        "/api/v1/assistant/route",
        headers=bearer(verified["session_token"]),
        json={"text": "review words"},
    )

    assert response.status_code == 502
    assert response.json()["code"] == "agent_failed"
