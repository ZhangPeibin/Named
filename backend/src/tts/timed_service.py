import hashlib

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from config import Settings
from media import MediaStore
from models import TimedSpeechAudio
from tts.schemas import SpeechAudioOut
from tts.timed_provider import TimedSpeechProvider, TimedWord


class TimedSpeechService:
    def __init__(
        self,
        settings: Settings,
        provider: TimedSpeechProvider,
        store: MediaStore,
    ) -> None:
        self.settings = settings
        self.provider = provider
        self.store = store

    def _cache_key(self, text: str, voice: str) -> str:
        payload = f"{text}|{voice}|{self.settings.tts_model}|{self.settings.tts_format}"
        return hashlib.sha256(payload.encode()).hexdigest()

    def _url(self, object_key: str) -> str:
        return f"{self.settings.media_url_prefix.rstrip('/')}/{object_key}"

    async def synthesize(
        self,
        session: AsyncSession,
        text: str,
    ) -> tuple[SpeechAudioOut, list[TimedWord]]:
        voice = self.settings.tts_voice_talk
        cache_key = self._cache_key(text, voice)
        row = await session.scalar(
            select(TimedSpeechAudio).where(TimedSpeechAudio.cache_key == cache_key)
        )
        if row is not None and await self.store.exists(row.object_key):
            return (
                SpeechAudioOut(url=self._url(row.object_key), status="ready"),
                [
                    TimedWord(
                        text=item["text"],
                        start_char=int(item["start_char"]),
                        end_char=int(item["end_char"]),
                        begin_ms=int(item["begin_ms"]),
                        end_ms=int(item["end_ms"]),
                    )
                    for item in row.words_json
                ],
            )

        result = await self.provider.synthesize(text, voice=voice)
        object_key = f"timed-audio/{cache_key}.{result.format}"
        await self.store.put(
            object_key,
            result.audio,
            "audio/mpeg" if result.format == "mp3" else "application/octet-stream",
        )
        words_json = [
            {
                "text": word.text,
                "start_char": word.start_char,
                "end_char": word.end_char,
                "begin_ms": word.begin_ms,
                "end_ms": word.end_ms,
            }
            for word in result.words
        ]
        if row is None:
            row = TimedSpeechAudio(
                cache_key=cache_key,
                object_key=object_key,
                format=result.format,
                words_json=words_json,
            )
            session.add(row)
        else:
            row.object_key = object_key
            row.format = result.format
            row.words_json = words_json
        await session.flush()
        return (
            SpeechAudioOut(url=self._url(object_key), status="ready"),
            result.words,
        )
