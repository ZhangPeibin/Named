import asyncio
from contextlib import asynccontextmanager
from io import BytesIO

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from PIL import Image
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from config import Settings, get_settings
from database import get_session
from discovery.agent import AgentFailed, get_discovery_agent
from discovery.schemas import (
    DiscoveryAgentOutput,
    DiscoveryFocus,
    SceneChunk,
    SceneCorrection,
    SceneExtension,
    ScenePayload,
    VarietyNote,
    WordChunk,
    WordPayload,
    WordSense,
)
from discovery.word_card_agent import get_word_card_agent
from discovery.word_lookup_agent import get_word_lookup_agent
from mailer import get_email_sender
from main import app
from models import Base, WordContent
from tts.provider import TTSError, TTSResult, get_tts_provider


class FakeEmailSender:
    def __init__(self) -> None:
        self.messages: list[tuple[str, str]] = []

    async def send_code(self, email: str, code: str) -> None:
        self.messages.append((email, code))

    @property
    def latest_code(self) -> str:
        return self.messages[-1][1]


def word_output(label: str = "tree") -> DiscoveryAgentOutput:
    return DiscoveryAgentOutput(
        input_language="zh",
        focus=DiscoveryFocus(
            kind="word",
            label_en=label,
            label_zh="树",
            confidence=0.95,
        ),
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
            chunks=[
                WordChunk(
                    phrase="a tall tree",
                    meaning_zh="一棵高大的树",
                    example_en="There is a tall tree by the lake.",
                ),
                WordChunk(
                    phrase="under a tree",
                    meaning_zh="在树下",
                    example_en="We sat under a tree.",
                ),
            ],
            variety_notes=[
                VarietyNote(
                    kind="spelling",
                    description_zh="英式英语中 tree 的拼写相同，这里只用于测试结构化字段。",
                    us="tree",
                    uk="tree",
                    example_en="The tree is old.",
                )
            ],
            scene_extensions=[
                SceneExtension(
                    label_en="leaf",
                    label_zh="树叶",
                    relationship="part of a tree",
                ),
                SceneExtension(
                    label_en="branch",
                    label_zh="树枝",
                    relationship="part of a tree",
                ),
                SceneExtension(
                    label_en="shade",
                    label_zh="树荫",
                    relationship="what a tree gives",
                ),
            ],
        ),
        warnings=[],
    )


def scene_output() -> DiscoveryAgentOutput:
    return DiscoveryAgentOutput(
        input_language="zh",
        focus=DiscoveryFocus(
            kind="scene",
            label_en="a moment in the park",
            label_zh="公园里的一段时光",
            confidence=0.86,
        ),
        word=None,
        scene=ScenePayload(
            natural_english="I rested in the park with my daughter.",
            key_chunks=[
                SceneChunk(
                    phrase="in the park",
                    meaning_native="在公园里",
                    example_en="We sat in the park.",
                ),
                SceneChunk(
                    phrase="spend time with",
                    meaning_native="和……一起度过",
                ),
            ],
            key_words=["park", "daughter"],
        ),
        warnings=[],
    )


def english_scene_output() -> DiscoveryAgentOutput:
    return DiscoveryAgentOutput(
        input_language="en",
        focus=DiscoveryFocus(
            kind="scene",
            label_en="liking a tree",
            label_zh="喜欢一棵树",
            confidence=0.88,
        ),
        word=None,
        scene=ScenePayload(
            natural_english="I really like the tree.",
            key_chunks=[
                SceneChunk(
                    phrase="really like",
                    meaning_native="非常喜欢",
                )
            ],
            key_words=["really", "tree"],
            correction=SceneCorrection(
                original="I very like the tree.",
                suggestion="I really like the tree.",
                note="very 不能直接修饰 like，这里用 really。",
            ),
        ),
        warnings=[],
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


class FakeWordCardAgent:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []

    async def generate(self, *, word: str, native_language: str) -> WordPayload:
        self.calls.append((word, native_language))
        return WordPayload(
            spelling=word,
            ipa={"us": "/kɑːrd/", "uk": "/kɑːd/"},
            pos=["n."],
            senses=[
                WordSense(
                    definition_en="card definition",
                    definition_zh="卡片释义",
                    example_en="This is a card example.",
                    example_zh="这是一个卡片例句。",
                )
            ],
            chunks=[
                WordChunk(
                    phrase=f"a {word}",
                    meaning_zh="一个卡片搭配",
                    example_en=f"This is a {word}.",
                )
            ],
        )


class FakeWordLookupAgent:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []
        self.fail = False

    async def resolve(self, *, text: str, native_language: str) -> str:
        self.calls.append((text, native_language))
        if self.fail:
            from discovery.word_lookup_agent import AgentFailed as WordLookupFailed

            raise WordLookupFailed("provider failed")
        return {
            "树": "tree",
            "running": "run",
            "runs": "run",
            "Paris": "Paris",
        }.get(text, text)


@asynccontextmanager
async def discovery_client(
    agent: FakeDiscoveryAgent,
    tts: FakeTTSProvider,
    media_root: str,
    discover_limit: int = 1000,
    card_agent: FakeWordCardAgent | None = None,
    lookup_agent: FakeWordLookupAgent | None = None,
):
    card_agent = card_agent or FakeWordCardAgent()
    lookup_agent = lookup_agent or FakeWordLookupAgent()
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
    app.dependency_overrides[get_word_card_agent] = lambda: card_agent
    app.dependency_overrides[get_word_lookup_agent] = lambda: lookup_agent

    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client, sender, session_factory, agent, tts, card_agent, lookup_agent
    finally:
        app.dependency_overrides.clear()
        await engine.dispose()


@pytest_asyncio.fixture
async def discovery_env(tmp_path):
    agent = FakeDiscoveryAgent()
    tts = FakeTTSProvider()
    async with discovery_client(agent, tts, str(tmp_path)) as (
        http,
        sender,
        sessions,
        _,
        _,
        _,
        _,
    ):
        yield http, sender, sessions, agent, tts


@pytest_asyncio.fixture
async def lookup_env(tmp_path):
    agent = FakeDiscoveryAgent()
    tts = FakeTTSProvider()
    card = FakeWordCardAgent()
    lookup = FakeWordLookupAgent()
    async with discovery_client(
        agent, tts, str(tmp_path), card_agent=card, lookup_agent=lookup
    ) as (http, sender, sessions, discovery, tts_service, card_agent, lookup_agent):
        yield http, sender, sessions, discovery, tts_service, card_agent, lookup_agent


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
    agent.output = word_output()
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
    assert body["candidates"] == []
    assert body["needs_confirmation"] is False
    assert body["word"]["chunks"][0]["phrase"] == "a tall tree"
    assert body["word"]["scene_extensions"][0]["label_zh"] == "树叶"
    assert body["word"]["variety_notes"][0]["kind"] == "spelling"
    assert body["word_id"]

    detail = await http.get(f"/api/v1/discoveries/{body['id']}", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["word"]["spelling"] == "tree"

    word = await http.get(f"/api/v1/words/{body['word_id']}", headers=headers)
    assert word.status_code == 200
    assert word.json()["content"]["spelling"] == "tree"


@pytest.mark.asyncio
async def test_scene_discovery_is_ready(discovery_env) -> None:
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
    assert body["status"] == "ready"
    assert body["focus_kind"] == "scene"
    assert body["word"] is None
    assert body["scene"]["natural_english"] == "I rested in the park with my daughter."
    assert body["scene"]["key_chunks"][0]["phrase"] == "in the park"
    assert body["scene"]["correction"] is None
    assert body["scene_audio"] is None
    assert body["candidates"] == []


@pytest.mark.asyncio
async def test_english_scene_correction(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    agent.output = english_scene_output()
    verified = await request_and_verify(http, sender, "scene-en@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "I very like the tree."},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["focus_kind"] == "scene"
    assert body["scene"]["natural_english"] == "I really like the tree."
    assert body["scene"]["correction"]["original"] == "I very like the tree."
    assert body["scene"]["correction"]["suggestion"] == "I really like the tree."


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
async def test_cached_word_skips_the_discovery_agent(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    verified = await request_and_verify(http, sender, "cached-word@example.com")
    headers = bearer(verified["session_token"])

    first = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert first.status_code == 201, first.text
    assert first.json()["word"]["spelling"] == "tree"
    assert len(agent.calls) == 1

    second = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "tree"},
    )
    assert second.status_code == 201, second.text
    body = second.json()
    assert body["word"]["spelling"] == "tree"
    assert body["status"] == "ready"
    assert body["audio"]["us"]["status"] == "unavailable"
    assert len(agent.calls) == 1

    third = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "Tree"},
    )
    assert third.status_code == 201, third.text
    assert third.json()["word"]["spelling"] == "tree"
    assert len(agent.calls) == 1


@pytest.mark.asyncio
async def test_card_content_is_not_returned_as_full(discovery_env) -> None:
    http, sender, sessions, _, _ = discovery_env
    verified = await request_and_verify(http, sender, "card-isolation@example.com")
    headers = bearer(verified["session_token"])

    response = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    word_id = body["word_id"]

    card_payload = WordPayload(
        spelling="tree",
        ipa={},
        pos=[],
        senses=[
            WordSense(
                definition_en="card definition",
                definition_zh="卡片释义",
                example_en="card example",
                example_zh="卡片例句",
            )
        ],
        grammar="CARD_MARKER",
    )
    async with sessions() as session:
        session.add(
            WordContent(
                word_id=word_id,
                native_language="zh",
                payload_json=card_payload.model_dump(mode="json"),
                content_level="card",
                source="ai",
                model="deepseek:deepseek-flash",
                prompt_version="discover-v1",
            )
        )
        await session.commit()

    word = await http.get(f"/api/v1/words/{word_id}", headers=headers)
    assert word.status_code == 200
    assert word.json()["content_level"] == "full"
    assert word.json()["content"]["grammar"] != "CARD_MARKER"

    words = await http.get("/api/v1/words", headers=headers)
    assert words.status_code == 200
    item = next(item for item in words.json()["words"] if item["id"] == word_id)
    assert item["content"]["grammar"] != "CARD_MARKER"


@pytest.mark.asyncio
async def test_lookup_card_returns_lightweight_content(lookup_env) -> None:
    http, sender, _, discovery, tts, card, lookup = lookup_env
    verified = await request_and_verify(http, sender, "lookup-card@example.com")
    headers = bearer(verified["session_token"])

    response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "tree", "level": "card"},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["content_level"] == "card"
    assert body["content"]["spelling"] == "tree"
    assert body["content"]["grammar"] == ""
    assert body["content"]["variety_notes"] == []
    assert body["content"]["scene_extensions"] == []
    assert len(body["content"]["senses"]) == 1
    assert body["audio"]["us"]["status"] == "unavailable"
    assert card.calls == [("tree", "zh")]
    assert discovery.calls == []
    assert tts.calls == []


@pytest.mark.asyncio
async def test_lookup_card_prefers_existing_full_content(lookup_env) -> None:
    http, sender, _, discovery, tts, card, lookup = lookup_env
    verified = await request_and_verify(http, sender, "lookup-full@example.com")
    headers = bearer(verified["session_token"])

    created = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert created.status_code == 201, created.text
    assert len(discovery.calls) == 1

    response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "tree", "level": "card"},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["content_level"] == "full"
    assert body["content"]["grammar"] == "可数名词；复数 trees。"
    assert card.calls == []
    assert lookup.calls == []
    assert tts.calls == []


@pytest.mark.asyncio
async def test_lookup_card_resolves_english_base_form(lookup_env) -> None:
    http, sender, _, discovery, _, card, lookup = lookup_env
    verified = await request_and_verify(http, sender, "lookup-base@example.com")
    headers = bearer(verified["session_token"])

    response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "running", "level": "card"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["content"]["spelling"] == "run"
    assert card.calls == [("run", "zh")]
    assert discovery.calls == []

    again = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "running", "level": "card"},
    )
    assert again.status_code == 200
    assert again.json()["content"]["spelling"] == "run"
    assert card.calls == [("run", "zh")]


@pytest.mark.asyncio
async def test_lookup_card_falls_back_when_english_resolution_fails(lookup_env) -> None:
    http, sender, _, discovery, _, card, lookup = lookup_env
    lookup.fail = True
    verified = await request_and_verify(http, sender, "lookup-fallback@example.com")
    headers = bearer(verified["session_token"])

    response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "running", "level": "card"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["content"]["spelling"] == "running"
    assert card.calls == [("running", "zh")]
    assert discovery.calls == []


@pytest.mark.asyncio
async def test_lookup_card_resolves_cjk(lookup_env) -> None:
    http, sender, _, discovery, _, card, lookup = lookup_env
    verified = await request_and_verify(http, sender, "lookup-cjk@example.com")
    headers = bearer(verified["session_token"])

    response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "树", "level": "card"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["content_level"] == "card"
    assert response.json()["content"]["spelling"] == "tree"
    assert card.calls == [("tree", "zh")]
    assert discovery.calls == []


@pytest.mark.asyncio
async def test_lookup_default_still_returns_full(lookup_env) -> None:
    http, sender, _, discovery, tts, card, lookup = lookup_env
    verified = await request_and_verify(http, sender, "lookup-default@example.com")
    headers = bearer(verified["session_token"])

    response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "树"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["content_level"] == "full"
    assert response.json()["content"]["spelling"] == "tree"
    assert len(discovery.calls) == 1
    assert card.calls == []
    assert len(tts.calls) == 2


@pytest.mark.asyncio
async def test_word_details_upgrades_card_to_full(lookup_env) -> None:
    http, sender, sessions, discovery, tts, card, _ = lookup_env
    verified = await request_and_verify(http, sender, "details-upgrade@example.com")
    headers = bearer(verified["session_token"])

    card_response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "tree", "level": "card"},
    )
    assert card_response.status_code == 200, card_response.text
    word_id = card_response.json()["id"]
    assert card_response.json()["content_level"] == "card"
    assert card.calls == [("tree", "zh")]
    assert discovery.calls == []

    response = await http.get(f"/api/v1/words/{word_id}/details", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["content_level"] == "full"
    assert body["content"]["spelling"] == "tree"
    assert body["content"]["grammar"] != ""
    assert body["audio"]["us"]["status"] == "unavailable"
    assert card.calls == [("tree", "zh")]
    assert len(discovery.calls) == 1
    assert tts.calls == []

    async with sessions() as session:
        rows = list(
            await session.scalars(select(WordContent).where(WordContent.word_id == word_id))
        )
    assert {row.content_level for row in rows} == {"card", "full"}


@pytest.mark.asyncio
async def test_word_details_returns_existing_full_without_generation(lookup_env) -> None:
    http, sender, _, discovery, _, card, _ = lookup_env
    verified = await request_and_verify(http, sender, "details-existing@example.com")
    headers = bearer(verified["session_token"])

    created = await http.post(
        "/api/v1/discoveries",
        headers=headers,
        data={"text": "树"},
    )
    assert created.status_code == 201, created.text
    word_id = created.json()["word_id"]
    assert len(discovery.calls) == 1

    response = await http.get(f"/api/v1/words/{word_id}/details", headers=headers)
    assert response.status_code == 200, response.text
    assert response.json()["content_level"] == "full"
    assert response.json()["content"]["spelling"] == "tree"
    assert len(discovery.calls) == 1
    assert card.calls == []


@pytest.mark.asyncio
async def test_word_details_concurrent_requests_generate_once(lookup_env) -> None:
    http, sender, _, discovery, _, card, _ = lookup_env
    verified = await request_and_verify(http, sender, "details-concurrent@example.com")
    headers = bearer(verified["session_token"])

    card_response = await http.get(
        "/api/v1/words/lookup",
        headers=headers,
        params={"text": "tree", "level": "card"},
    )
    assert card_response.status_code == 200, card_response.text
    word_id = card_response.json()["id"]
    assert card.calls == [("tree", "zh")]

    responses = await asyncio.gather(
        http.get(f"/api/v1/words/{word_id}/details", headers=headers),
        http.get(f"/api/v1/words/{word_id}/details", headers=headers),
    )
    assert all(response.status_code == 200 for response in responses)
    assert len(discovery.calls) == 1


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
    assert body["word"]["spelling"] == "tree"
    assert body["audio"]["us"]["status"] == "unavailable"
    assert body["audio"]["uk"]["status"] == "unavailable"
    assert len(tts.calls) == 0

    word = await http.get(f"/api/v1/words/{body['word_id']}", headers=headers)
    assert word.status_code == 200
    assert word.json()["audio"]["us"]["status"] == "ready"
    assert len(tts.calls) == 2

    us_url = word.json()["audio"]["us"]["url"]
    assert us_url is not None
    audio = await http.get(us_url, headers=headers)
    assert audio.status_code == 200
    assert audio.content == b"audio-us-tree"

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
        _,
        _,
        _,
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


@pytest.mark.asyncio
async def test_identical_text_discovery_is_reused_within_cooldown(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    verified = await request_and_verify(http, sender, "dedupe@example.com")
    headers = bearer(verified["session_token"])
    agent.output = word_output("tree")

    first = await http.post("/api/v1/discoveries", headers=headers, data={"text": "树"})
    second = await http.post("/api/v1/discoveries", headers=headers, data={"text": "树"})
    assert first.status_code == 201
    assert second.status_code == 201
    assert first.json()["id"] == second.json()["id"]
    assert len(agent.calls) == 1


@pytest.mark.asyncio
async def test_words_are_deduplicated_and_progress_is_tracked(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    verified = await request_and_verify(http, sender, "words@example.com")
    headers = bearer(verified["session_token"])

    agent.output = word_output("tree")
    first = await http.post("/api/v1/discoveries", headers=headers, data={"text": "树"})
    assert first.status_code == 201
    second = await http.post("/api/v1/discoveries", headers=headers, data={"text": "tree"})
    assert second.status_code == 201

    response = await http.get("/api/v1/words", headers=headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["stats"]["total"] == 1
    assert len(body["words"]) == 1
    word = body["words"][0]
    assert word["label_en"] == "tree"
    assert word["discovery_count"] == 2
    assert word["status"] == "needs_review"

    word_id = word["id"]
    known = await http.patch(
        f"/api/v1/words/{word_id}/progress",
        headers=headers,
        json={"known": True},
    )
    assert known.status_code == 200
    assert known.json()["status"] == "known"

    response = await http.get("/api/v1/words", headers=headers)
    word = response.json()["words"][0]
    assert word["status"] == "known"


@pytest.mark.asyncio
async def test_word_attempt_is_tracked_and_moves_status(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    verified = await request_and_verify(http, sender, "attempt@example.com")
    headers = bearer(verified["session_token"])
    agent.output = word_output("tree")

    created = await http.post("/api/v1/discoveries", headers=headers, data={"text": "树"})
    assert created.status_code == 201
    word_id = created.json()["word_id"]

    attempt = await http.post(
        f"/api/v1/words/{word_id}/attempt",
        headers=headers,
        json={"attempted_text": "tre"},
    )
    assert attempt.status_code == 200, attempt.text
    assert attempt.json()["status"] == "attempted"
    assert attempt.json()["attempt_count"] == 1
    assert attempt.json()["last_attempt_at"]

    words = (await http.get("/api/v1/words", headers=headers)).json()["words"]
    assert words[0]["status"] == "attempted"
    assert words[0]["attempt_count"] == 1

    empty = await http.post(
        f"/api/v1/words/{word_id}/attempt",
        headers=headers,
        json={"attempted_text": ""},
    )
    assert empty.status_code == 422


@pytest.mark.asyncio
async def test_word_attempt_rejects_another_account(discovery_env) -> None:
    http, sender, _, agent, _ = discovery_env
    owner = await request_and_verify(http, sender, "attempt-owner@example.com")
    other = await request_and_verify(http, sender, "attempt-other@example.com")
    agent.output = word_output("tree")

    created = await http.post(
        "/api/v1/discoveries",
        headers=bearer(owner["session_token"]),
        data={"text": "树"},
    )
    word_id = created.json()["word_id"]

    response = await http.post(
        f"/api/v1/words/{word_id}/attempt",
        headers=bearer(other["session_token"]),
        json={"attempted_text": "tree"},
    )
    assert response.status_code == 404
