from contextlib import asynccontextmanager
from io import BytesIO

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from PIL import Image
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from config import Settings, get_settings
from database import get_session
from discovery.agent import AgentFailed, get_discovery_agent
from discovery.schemas import (
    DiscoveryAgentOutput,
    DiscoveryFocus,
    WordCandidate,
    WordPayload,
    WordSense,
)
from mailer import get_email_sender
from main import app
from models import Base
from tts.provider import TTSError, TTSResult, get_tts_provider


class FakeEmailSender:
    def __init__(self) -> None:
        self.messages: list[tuple[str, str]] = []

    async def send_code(self, email: str, code: str) -> None:
        self.messages.append((email, code))

    @property
    def latest_code(self) -> str:
        return self.messages[-1][1]


def word_output(
    label: str = "tree",
    *,
    needs_confirmation: bool = False,
) -> DiscoveryAgentOutput:
    return DiscoveryAgentOutput(
        input_language="zh",
        focus=DiscoveryFocus(
            kind="word",
            label_en=label,
            label_zh="树",
            confidence=0.95,
        ),
        candidates=[
            WordCandidate(
                label_en=label,
                label_zh="树",
                confidence=0.95,
                reason="最直接对应的英语名称",
            )
        ],
        word=WordPayload(
            spelling=label,
            ipa={"us": "/triː/", "uk": "/triː/"},
            pos=["noun"],
            senses=[
                WordSense(
                    definition_en="a tall plant with a trunk and branches",
                    definition_zh="有树干和树枝的高大植物",
                    example_en="There is a tree in the park.",
                    example_zh="公园里有一棵树。",
                )
            ],
            grammar="可数名词；复数 trees。",
            related=["leaf", "branch"],
            scene_extensions=["sit under a tree"],
        ),
        needs_confirmation=needs_confirmation,
    )


def scene_output() -> DiscoveryAgentOutput:
    return DiscoveryAgentOutput(
        input_language="zh",
        focus=DiscoveryFocus(
            kind="scene",
            label_en="a moment from my day",
            label_zh="今天的一段生活",
            confidence=0.8,
        ),
        candidates=[
            WordCandidate(
                label_en="a moment from my day",
                label_zh="今天的一段生活",
                confidence=0.8,
                reason="输入更像一段情境",
            )
        ],
        word=None,
        needs_confirmation=True,
    )


class FakeDiscoveryAgent:
    def __init__(self, output: DiscoveryAgentOutput | None = None) -> None:
        self.output = output or word_output()
        self.calls: list[tuple[str, str, str | None, str | None, bytes | None]] = []
        self.fail = False

    async def analyze(
        self,
        text: str,
        native_language: str,
        context: str | None = None,
        confirmed_label: str | None = None,
        image: bytes | None = None,
        image_media_type: str | None = None,
    ) -> DiscoveryAgentOutput:
        self.calls.append((text, native_language, context, confirmed_label, image))
        if self.fail:
            raise AgentFailed("provider failed")
        if confirmed_label is not None:
            return word_output(confirmed_label)
        return self.output


class FakeTTSProvider:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str, str, float, str]] = []
        self.fail = False

    async def synthesize(
        self,
        text: str,
        region: str,
        voice: str,
        rate: float,
        fmt: str,
    ) -> TTSResult:
        self.calls.append((text, region, voice, rate, fmt))
        if self.fail:
            raise TTSError("provider failed")
        return TTSResult(data=f"audio-{region}-{text}".encode(), format=fmt)


@asynccontextmanager
async def discovery_client(
    agent: FakeDiscoveryAgent,
    tts: FakeTTSProvider,
    media_root: str,
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
        tts_format="mp3",
        tts_rate=1.0,
        media_root=media_root,
        media_url_prefix="/api/v1/audio",
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
    app.dependency_overrides[get_discovery_agent] = lambda: agent
    app.dependency_overrides[get_tts_provider] = lambda: tts

    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client, sender, session_factory
    finally:
        app.dependency_overrides.clear()
        await engine.dispose()


@pytest_asyncio.fixture
async def discovery_env(tmp_path):
    agent = FakeDiscoveryAgent()
    tts = FakeTTSProvider()
    async with discovery_client(agent, tts, str(tmp_path)) as (http, sender, sessions):
        yield http, sender, sessions, agent, tts


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


async def request_and_verify(client, sender, email: str) -> dict:
    response = await client.post("/api/v1/auth/code", json={"email": email})
    assert response.status_code == 202, response.text
    code = sender.latest_code

    response = await client.post(
        "/api/v1/auth/verify",
        json={
            "email": email,
            "code": code,
            "initial_soul": {"native_language": "zh"},
        },
    )
    assert response.status_code == 200, response.text
    return response.json()


@pytest.mark.asyncio
async def test_text_discovery_auto_ready(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    agent.output = word_output(needs_confirmation=False)
    verified = await request_and_verify(http, sender, "discover@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树", "context": "今天在公园里看到一棵树"},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["status"] == "ready"
    assert body["focus_kind"] == "word"
    assert body["word"]["spelling"] == "tree"
    assert body["candidates"][0]["selected"] is True
    assert body["word_id"]

    detail = await http.get(f"/api/v1/discoveries/{body['id']}", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["word"]["spelling"] == "tree"

    word = await http.get(f"/api/v1/words/{body['word_id']}", headers=headers)
    assert word.status_code == 200
    assert word.json()["content"]["spelling"] == "tree"


@pytest.mark.asyncio
async def test_text_discovery_needs_confirmation_then_focus(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    agent.output = word_output(needs_confirmation=True)
    verified = await request_and_verify(http, sender, "confirm@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "needs_confirmation"
    assert body["word"] is None

    candidate_id = body["candidates"][0]["id"]
    response = await http.post(
        f"/api/v1/discoveries/{body['id']}/focus",
        headers=headers,
        json={"candidate_id": candidate_id},
    )
    assert response.status_code == 200, response.text
    focused = response.json()
    assert focused["status"] == "ready"
    assert focused["word"]["spelling"] == "tree"
    assert agent.calls[-1][3] == "tree"

    detail = await http.get(f"/api/v1/discoveries/{body['id']}", headers=headers)
    assert detail.json()["status"] == "ready"


@pytest.mark.asyncio
async def test_focus_can_choose_whole_scene(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    agent.output = scene_output()
    verified = await request_and_verify(http, sender, "scene@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "今天在公园里和女儿休息了一会儿"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "needs_confirmation"
    assert body["focus_kind"] == "scene"

    response = await http.post(
        f"/api/v1/discoveries/{body['id']}/focus",
        headers=headers,
        json={"whole_scene": True},
    )
    assert response.status_code == 200
    focused = response.json()
    assert focused["status"] == "ready"
    assert focused["focus_kind"] == "scene"
    assert focused["word"] is None


@pytest.mark.asyncio
async def test_focus_can_override_label(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    agent.output = word_output(needs_confirmation=True)
    verified = await request_and_verify(http, sender, "override@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    body = response.json()

    response = await http.post(
        f"/api/v1/discoveries/{body['id']}/focus",
        headers=headers,
        json={"label_en": "big tree"},
    )
    assert response.status_code == 200, response.text
    focused = response.json()
    assert focused["word"]["spelling"] == "big tree"
    assert agent.calls[-1][3] == "big tree"


@pytest.mark.asyncio
async def test_discovery_is_isolated(discovery_env) -> None:
    http, sender, _, _, _ = discovery_env
    first = await request_and_verify(http, sender, "first-discovery@example.com")
    second = await request_and_verify(http, sender, "second-discovery@example.com")

    response = await http.post(
        "/api/v1/discoveries",
        headers=bearer(first["session_token"]),
        data={"text": "树"},
    )
    assert response.status_code == 201
    discovery_id = response.json()["id"]

    response = await http.get(
        f"/api/v1/discoveries/{discovery_id}",
        headers=bearer(second["session_token"]),
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_agent_failure_returns_502(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    verified = await request_and_verify(http, sender, "fail@example.com")
    agent.fail = True

    response = await http.post(
        "/api/v1/discoveries",
        headers=bearer(verified["session_token"]),
        data={"text": "树"},
    )
    assert response.status_code == 502
    assert response.json()["code"] == "agent_failed"


@pytest.mark.asyncio
async def test_blank_text_is_rejected(discovery_env) -> None:
    http, sender, _, _, _ = discovery_env
    verified = await request_and_verify(http, sender, "blank@example.com")

    response = await http.post(
        "/api/v1/discoveries",
        headers=bearer(verified["session_token"]),
        data={"text": "   "},
    )
    assert response.status_code == 400
    assert response.json()["code"] == "input_required"


@pytest.mark.asyncio
async def test_word_not_found_returns_404(discovery_env) -> None:
    http, sender, _, _, _ = discovery_env
    verified = await request_and_verify(http, sender, "word404@example.com")

    response = await http.get(
        "/api/v1/words/does-not-exist",
        headers=bearer(verified["session_token"]),
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_word_audio_is_generated_and_cached(discovery_env) -> None:
    http, sender, _, _, tts = discovery_env
    verified = await request_and_verify(http, sender, "audio@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["audio"]["us"]["status"] == "ready"
    assert body["audio"]["uk"]["status"] == "ready"
    assert len(tts.calls) == 2

    us_url = body["audio"]["us"]["url"]
    assert us_url is not None
    audio = await http.get(us_url, headers=headers)
    assert audio.status_code == 200
    assert audio.content == b"audio-us-tree"

    word = await http.get(f"/api/v1/words/{body['word_id']}", headers=headers)
    assert word.status_code == 200
    assert word.json()["audio"]["us"]["url"] == us_url

    cached = await http.get(f"/api/v1/discoveries/{body['id']}", headers=headers)
    assert cached.status_code == 200
    assert cached.json()["audio"]["us"]["url"] == us_url
    assert len(tts.calls) == 2


@pytest.mark.asyncio
async def test_tts_failure_does_not_block_word_content(discovery_env) -> None:
    http, sender, _, _, tts = discovery_env
    verified = await request_and_verify(http, sender, "audio-fail@example.com")
    tts.fail = True

    response = await http.post(
        "/api/v1/discoveries",
        headers=bearer(verified["session_token"]),
        data={"text": "树"},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["word"]["spelling"] == "tree"
    assert body["audio"]["us"]["status"] == "unavailable"
    assert body["audio"]["uk"]["status"] == "unavailable"


@pytest.mark.asyncio
async def test_audio_requires_auth_and_unknown_key_returns_404(discovery_env) -> None:
    http, sender, _, _, _ = discovery_env
    verified = await request_and_verify(http, sender, "audio-auth@example.com")

    response = await http.get("/api/v1/audio/word-audio/missing.mp3")
    assert response.status_code == 401

    response = await http.get(
        "/api/v1/audio/word-audio/missing.mp3",
        headers=bearer(verified["session_token"]),
    )
    assert response.status_code == 404


def png_bytes() -> bytes:
    image = Image.new("RGB", (16, 16), (20, 120, 40))
    output = BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


@pytest.mark.asyncio
async def test_image_discovery_and_delete(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    verified = await request_and_verify(http, sender, "image@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        files={"image": ("tree.png", png_bytes(), "image/png")},
        data={"text": "树"},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["input_type"] == "image"
    assert body["image_url"]
    assert agent.calls[-1][4] is not None

    image = await http.get(body["image_url"], headers=headers)
    assert image.status_code == 200
    assert image.headers["content-type"] == "image/jpeg"
    assert image.content.startswith(b"\xff\xd8")

    other = await request_and_verify(http, sender, "image-other@example.com")
    response = await http.get(
        body["image_url"],
        headers=bearer(other["session_token"]),
    )
    assert response.status_code == 404

    response = await http.delete(f"/api/v1/discoveries/{body['id']}", headers=headers)
    assert response.status_code == 204

    response = await http.get(body["image_url"], headers=headers)
    assert response.status_code == 404

    response = await http.get(f"/api/v1/discoveries/{body['id']}", headers=headers)
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_image_only_discovery_is_allowed(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    verified = await request_and_verify(http, sender, "image-only@example.com")

    response = await http.post(
        "/api/v1/discoveries",
        headers=bearer(verified["session_token"]),
        files={"image": ("tree.png", png_bytes(), "image/png")},
    )
    assert response.status_code == 201, response.text
    assert response.json()["input_type"] == "image"
    assert agent.calls[-1][0] == ""


@pytest.mark.asyncio
async def test_invalid_image_is_rejected(discovery_env) -> None:
    http, sender, _, _, _ = discovery_env
    verified = await request_and_verify(http, sender, "bad-image@example.com")

    response = await http.post(
        "/api/v1/discoveries",
        headers=bearer(verified["session_token"]),
        files={"image": ("bad.png", b"not-an-image", "image/png")},
    )
    assert response.status_code == 400
    assert response.json()["code"] == "invalid_image"


@pytest.mark.asyncio
async def test_missing_text_and_image_is_rejected(discovery_env) -> None:
    http, sender, _, _, _ = discovery_env
    verified = await request_and_verify(http, sender, "empty-input@example.com")

    response = await http.post(
        "/api/v1/discoveries",
        headers=bearer(verified["session_token"]),
    )
    assert response.status_code == 400
    assert response.json()["code"] == "input_required"


@pytest.mark.asyncio
async def test_discover_rate_limit(tmp_path) -> None:
    agent = FakeDiscoveryAgent()
    tts = FakeTTSProvider()
    async with discovery_client(agent, tts, str(tmp_path), discover_limit=1) as (
        http,
        sender,
        _,
    ):
        verified = await request_and_verify(http, sender, "rate-discover@example.com")
        headers = bearer(verified["session_token"])

        first = await http.post(
            "/api/v1/discoveries",
            headers=headers,
            data={"text": "树"},
        )
        assert first.status_code == 201

        second = await http.post(
            "/api/v1/discoveries",
            headers=headers,
            data={"text": "树"},
        )
        assert second.status_code == 429
        assert second.headers["Retry-After"]
        assert second.json()["code"] == "rate_limited"
