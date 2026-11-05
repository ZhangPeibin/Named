import asyncio
from dataclasses import dataclass
from typing import Protocol

import dashscope
from dashscope.audio.tts_v2 import AudioFormat, SpeechSynthesizer

from config import Settings, get_settings


class TTSNotConfigured(Exception):
    pass


class TTSError(Exception):
    pass


@dataclass
class TTSResult:
    data: bytes
    format: str


class TTSProvider(Protocol):
    async def synthesize(
        self,
        text: str,
        region: str,
        voice: str,
        rate: float,
        fmt: str,
    ) -> TTSResult: ...


class QwenTTSProvider:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    async def synthesize(
        self,
        text: str,
        region: str,
        voice: str,
        rate: float,
        fmt: str,
    ) -> TTSResult:
        if not self.settings.dashscope_api_key:
            raise TTSNotConfigured
        try:
            return await asyncio.to_thread(self._synthesize_sync, text, voice, rate)
        except Exception as exc:
            raise TTSError(str(exc)) from exc

    def _synthesize_sync(self, text: str, voice: str, rate: float) -> TTSResult:
        dashscope.api_key = self.settings.dashscope_api_key
        if self.settings.dashscope_websocket_url:
            dashscope.base_websocket_api_url = self.settings.dashscope_websocket_url

        synthesizer = SpeechSynthesizer(
            model=self.settings.tts_model,
            voice=voice,
            format=AudioFormat.MP3_22050HZ_MONO_256KBPS,
            speech_rate=rate,
            language_hints=["en"],
        )
        audio = synthesizer.call(text)
        if not audio:
            raise TTSError("Empty TTS response.")
        return TTSResult(data=audio, format="mp3")


def get_tts_provider() -> TTSProvider:
    return QwenTTSProvider(get_settings())
