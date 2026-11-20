import asyncio
import re
from dataclasses import dataclass
from typing import Protocol

from dashscope import Client

from config import Settings, get_settings


class TimedSpeechNotConfigured(Exception):
    pass


class TimedSpeechError(Exception):
    pass


@dataclass(frozen=True)
class TimedWord:
    text: str
    start_char: int
    end_char: int
    begin_ms: int
    end_ms: int


@dataclass(frozen=True)
class TimedSpeechResult:
    audio: bytes
    format: str
    words: list[TimedWord]


class TimedSpeechProvider(Protocol):
    async def synthesize(self, text: str, *, voice: str) -> TimedSpeechResult: ...


def _align_words(text: str, raw_words: list[dict]) -> list[TimedWord]:
    words: list[TimedWord] = []
    cursor = 0
    lower = text.lower()
    for raw in raw_words:
        token = str(raw.get("text", "")).strip()
        needle = re.sub(r"^[^A-Za-z0-9']+|[^A-Za-z0-9']+$", "", token).lower()
        if not needle:
            continue
        index = lower.find(needle, cursor)
        if index < 0:
            continue
        begin = int(raw.get("begin_time", 0))
        end = int(raw.get("end_time", begin))
        words.append(
            TimedWord(
                text=text[index : index + len(needle)],
                start_char=index,
                end_char=index + len(needle),
                begin_ms=begin,
                end_ms=end,
            )
        )
        cursor = index + len(needle)
    return words


class DashScopeTimedSpeechProvider:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    async def synthesize(self, text: str, *, voice: str) -> TimedSpeechResult:
        if not self.settings.dashscope_api_key:
            raise TimedSpeechNotConfigured
        try:
            return await asyncio.to_thread(self._synthesize_sync, text, voice)
        except (TimedSpeechNotConfigured, TimedSpeechError):
            raise
        except Exception as exc:
            raise TimedSpeechError(str(exc)) from exc

    def _synthesize_sync(self, text: str, voice: str) -> TimedSpeechResult:
        client = Client(
            api_key=self.settings.dashscope_api_key,
            workspace=self.settings.dashscope_workspace,
            region=self.settings.dashscope_region,
            timeout=60,
            max_retries=0,
            raise_on_error=True,
        )
        audio = bytearray()
        words_by_sentence: dict[int, list[dict]] = {}
        try:
            stream = client.audio.tts.http.stream(
                text,
                model=self.settings.tts_model,
                voice=voice,
                format="mp3",
                parameters={"word_timestamp_enabled": True},
                timeout=60,
            )
            try:
                for chunk in stream:
                    if chunk.audio:
                        audio.extend(chunk.audio)
                    sentence = chunk.sentence
                    if sentence and sentence.get("words"):
                        index = int(sentence.get("index", 0))
                        words = list(sentence["words"])
                        if len(words) > len(words_by_sentence.get(index, [])):
                            words_by_sentence[index] = words
            finally:
                stream.close()
        finally:
            client.close()

        raw_words = [
            word for index in sorted(words_by_sentence) for word in words_by_sentence[index]
        ]
        if not audio or not raw_words:
            raise TimedSpeechError("Timed speech returned no audio or timestamps.")
        words = _align_words(text, raw_words)
        if not words:
            raise TimedSpeechError("No words could be aligned to the passage.")
        return TimedSpeechResult(bytes(audio), "mp3", words)


def get_timed_speech_provider() -> TimedSpeechProvider:
    return DashScopeTimedSpeechProvider(get_settings())
