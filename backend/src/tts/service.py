import hashlib
import logging
from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from config import Settings
from media import MediaStore
from models import TTSAudio, Word, WordAudio
from tts.provider import TTSProvider
from tts.schemas import AudioOut, AudioTrackOut, SpeechAudioOut

logger = logging.getLogger(__name__)


def _content_type(fmt: str) -> str:
    return {
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "ogg": "audio/ogg",
    }.get(fmt, "application/octet-stream")


class WordAudioService:
    def __init__(
        self,
        settings: Settings,
        provider: TTSProvider,
        store: MediaStore,
    ) -> None:
        self.settings = settings
        self.provider = provider
        self.store = store

    def _cache_key(self, text: str, region: str, voice: str) -> str:
        payload = (
            f"{text}|{region}|{voice}|{self.settings.tts_model}|"
            f"{self.settings.tts_rate}|{self.settings.tts_format}"
        )
        return hashlib.sha256(payload.encode()).hexdigest()

    def _url(self, object_key: str) -> str:
        return f"{self.settings.media_url_prefix.rstrip('/')}/{object_key}"

    async def for_word(self, session: AsyncSession, word: Word) -> AudioOut:
        tracks: dict[str, AudioTrackOut] = {}
        voices = {
            "us": self.settings.tts_voice_us,
            "uk": self.settings.tts_voice_uk,
        }

        for region, voice in voices.items():
            cache_key = self._cache_key(word.label_en, region, voice)
            row = await session.scalar(select(WordAudio).where(WordAudio.cache_key == cache_key))

            if row is not None and await self.store.exists(row.object_key):
                tracks[region] = AudioTrackOut(
                    url=self._url(row.object_key),
                    status="ready",
                )
                continue

            try:
                result = await self.provider.synthesize(
                    word.label_en,
                    region,
                    voice,
                    self.settings.tts_rate,
                    self.settings.tts_format,
                )
                object_key = f"word-audio/{cache_key}.{result.format}"
                await self.store.put(
                    object_key,
                    result.data,
                    _content_type(result.format),
                )
            except Exception:
                logger.warning("Word audio unavailable for region %s", region)
                tracks[region] = AudioTrackOut(status="unavailable")
                continue

            if row is None:
                row = WordAudio(
                    word_id=word.id,
                    region=region,
                    voice_id=voice,
                    format=result.format,
                    rate=self.settings.tts_rate,
                    cache_key=cache_key,
                    object_key=object_key,
                    source="tts",
                )
                session.add(row)
            else:
                row.object_key = object_key
                row.format = result.format

            await session.flush()
            tracks[region] = AudioTrackOut(
                url=self._url(object_key),
                status="ready",
            )

        await session.commit()
        return AudioOut(us=tracks["us"], uk=tracks["uk"])


class SpeechAudioService:
    def __init__(
        self,
        settings: Settings,
        provider: TTSProvider,
        store: MediaStore,
    ) -> None:
        self.settings = settings
        self.provider = provider
        self.store = store

    def _cache_key(self, text: str, voice: str) -> str:
        payload = (
            f"{text}|{voice}|{self.settings.tts_model}|"
            f"{self.settings.tts_rate}|{self.settings.tts_format}"
        )
        return hashlib.sha256(payload.encode()).hexdigest()

    def _url(self, object_key: str) -> str:
        return f"{self.settings.media_url_prefix.rstrip('/')}/{object_key}"

    def _expires_at(self):
        ttl = self.settings.talk_audio_ttl_seconds
        return utcnow() + timedelta(seconds=ttl) if ttl > 0 else None

    async def synthesize(
        self,
        session: AsyncSession,
        text: str,
        voice: str | None = None,
    ) -> tuple[SpeechAudioOut, str | None]:
        voice_id = voice or self.settings.tts_voice_talk
        cache_key = self._cache_key(text, voice_id)
        now = utcnow()

        row = await session.scalar(select(TTSAudio).where(TTSAudio.cache_key == cache_key))
        if (
            row is not None
            and row.expires_at is not None
            and row.expires_at > now
            and await self.store.exists(row.object_key)
        ):
            return (
                SpeechAudioOut(url=self._url(row.object_key), status="ready"),
                row.object_key,
            )

        try:
            result = await self.provider.synthesize(
                text,
                "talk",
                voice_id,
                self.settings.tts_rate,
                self.settings.tts_format,
            )
            object_key = f"talk-audio/{cache_key}.{result.format}"
            await self.store.put(
                object_key,
                result.data,
                _content_type(result.format),
            )
        except Exception:
            logger.warning("Talk audio unavailable")
            return SpeechAudioOut(status="unavailable"), None

        if row is None:
            row = TTSAudio(
                cache_key=cache_key,
                object_key=object_key,
                format=result.format,
                source="tts",
                expires_at=self._expires_at(),
            )
            session.add(row)
        else:
            row.object_key = object_key
            row.format = result.format
            row.expires_at = self._expires_at()

        await session.flush()
        return (
            SpeechAudioOut(url=self._url(object_key), status="ready"),
            object_key,
        )
