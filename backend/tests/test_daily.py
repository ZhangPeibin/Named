import pytest
import pytest_asyncio
from test_discovery import FakeTTSProvider, bearer, discovery_client, request_and_verify

from daily.agent import get_daily_read_agent
from daily.schemas import DailyReadAgentOutput
from daily.translation_agent import get_daily_translation_agent
from main import app
from tts.timed_provider import TimedSpeechResult, TimedWord, get_timed_speech_provider


class FakeDailyReadAgent:
    def __init__(self) -> None:
        self.calls: list[tuple[list[str], str]] = []

    async def write(
        self,
        *,
        target_words: list[str],
        native_language: str,
        theme: str,
    ) -> DailyReadAgentOutput:
        self.calls.append((target_words, native_language))
        words = ", ".join(target_words)
        return DailyReadAgentOutput(
            title="A Quiet Morning",
            passage=(
                "Today I noticed a small thing near the window. "
                "I stopped to look at it and felt quiet. "
                f"The words {words} came to mind as I watched the light move."
            ),
            target_words=target_words[:3],
            question="What did you notice today?",
        )


class FakeDailyTranslationAgent:
    def __init__(self) -> None:
        self.calls: list[tuple[list[str], str]] = []

    async def translate(
        self,
        *,
        sentences: list[str],
        native_language: str,
    ) -> list[str]:
        self.calls.append((sentences, native_language))
        return [f"translation {index + 1}" for index, _ in enumerate(sentences)]


class FakeTimedSpeechProvider:
    async def synthesize(self, text: str, *, voice: str) -> TimedSpeechResult:
        return TimedSpeechResult(
            audio=b"fake-mp3",
            format="mp3",
            words=[
                TimedWord("Today", 0, 5, 0, 300),
                TimedWord("quiet", text.index("quiet"), text.index("quiet") + 5, 900, 1200),
            ],
        )


class FakeDiscoveryAgent:
    async def analyze(self, *args, **kwargs):
        raise AssertionError("discovery should not be called")


@pytest_asyncio.fixture
async def daily_env(tmp_path):
    tts = FakeTTSProvider()
    daily_agent = FakeDailyReadAgent()
    translation_agent = FakeDailyTranslationAgent()
    async with discovery_client(
        FakeDiscoveryAgent(),
        tts,
        str(tmp_path),
    ) as (http, sender, sessions):
        app.dependency_overrides[get_daily_read_agent] = lambda: daily_agent
        app.dependency_overrides[get_daily_translation_agent] = lambda: translation_agent
        app.dependency_overrides[get_timed_speech_provider] = lambda: FakeTimedSpeechProvider()
        try:
            yield http, sender, daily_agent, translation_agent, tts
        finally:
            app.dependency_overrides.pop(get_daily_read_agent, None)
            app.dependency_overrides.pop(get_daily_translation_agent, None)
            app.dependency_overrides.pop(get_timed_speech_provider, None)


@pytest.mark.asyncio
async def test_daily_read_is_created_once_per_day(daily_env) -> None:
    http, sender, agent, translation_agent, tts = daily_env
    verified = await request_and_verify(http, sender, "daily@example.com")
    headers = bearer(verified["session_token"])

    first = await http.get("/api/v1/daily/read", headers=headers)
    assert first.status_code == 200, first.text
    body = first.json()
    assert body["title"] == "A Quiet Morning"
    assert "quiet" in body["passage"]
    assert body["audio"]["status"] == "ready"
    assert body["words"]
    assert body["target_words"]
    assert agent.calls

    second = await http.get("/api/v1/daily/read", headers=headers)
    assert second.status_code == 200, second.text
    assert second.json()["passage"] == body["passage"]
    assert len(agent.calls) == 1
    assert body["completed"] is False
    assert body["streak"] == 0


@pytest.mark.asyncio
async def test_daily_read_requires_auth(daily_env) -> None:
    http, _, _, _, _ = daily_env
    response = await http.get("/api/v1/daily/read")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_daily_translation_is_sentence_aligned_and_cached(daily_env) -> None:
    http, sender, _, translation_agent, _ = daily_env
    verified = await request_and_verify(http, sender, "daily-translation@example.com")
    headers = bearer(verified["session_token"])

    reading = await http.get("/api/v1/daily/read", headers=headers)
    assert reading.status_code == 200, reading.text

    first = await http.get("/api/v1/daily/read/translation", headers=headers)
    assert first.status_code == 200, first.text
    body = first.json()
    assert body["language"] == "zh"
    assert len(body["lines"]) == 3
    assert body["lines"][0]["text"].startswith("Today I noticed")
    assert body["lines"][0]["translation"] == "translation 1"
    assert len(translation_agent.calls) == 1

    second = await http.get("/api/v1/daily/read/translation", headers=headers)
    assert second.status_code == 200, second.text
    assert second.json() == body
    assert len(translation_agent.calls) == 1


@pytest.mark.asyncio
async def test_daily_read_completion_is_idempotent(daily_env) -> None:
    http, sender, _, _, _ = daily_env
    verified = await request_and_verify(http, sender, "daily-complete@example.com")
    headers = bearer(verified["session_token"])

    reading = await http.get("/api/v1/daily/read", headers=headers)
    assert reading.status_code == 200, reading.text

    first = await http.post(
        "/api/v1/daily/read/complete",
        headers=headers,
        json={"duration_seconds": 126},
    )
    assert first.status_code == 200, first.text
    body = first.json()
    assert body["completed"] is True
    assert body["streak"] == 1
    assert body["word_count"] > 0
    assert body["duration_seconds"] == 126

    second = await http.post(
        "/api/v1/daily/read/complete",
        headers=headers,
        json={"duration_seconds": 300},
    )
    assert second.status_code == 200, second.text
    assert second.json()["duration_seconds"] == 126

    refreshed = await http.get("/api/v1/daily/read", headers=headers)
    assert refreshed.status_code == 200, refreshed.text
    assert refreshed.json()["completed"] is True
    assert refreshed.json()["streak"] == 1


@pytest.mark.asyncio
async def test_daily_read_can_be_opened_by_date(daily_env) -> None:
    http, sender, _, _, _ = daily_env
    verified = await request_and_verify(http, sender, "daily-date@example.com")
    headers = bearer(verified["session_token"])

    today = await http.get("/api/v1/daily/read", headers=headers)
    assert today.status_code == 200, today.text
    reading_date = today.json()["date"]

    historical = await http.get(
        "/api/v1/daily/read",
        headers=headers,
        params={"date": reading_date},
    )
    assert historical.status_code == 200, historical.text
    assert historical.json()["passage"] == today.json()["passage"]

    invalid = await http.get(
        "/api/v1/daily/read",
        headers=headers,
        params={"date": "not-a-date"},
    )
    assert invalid.status_code == 400
    assert invalid.json()["code"] == "invalid_date"
