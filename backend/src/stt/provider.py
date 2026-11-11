import asyncio
import base64
import io
import json
import wave
from typing import Protocol

from dashscope import Client
from dashscope.errors import BadRequestError

from config import Settings, get_settings


class STTNotConfigured(Exception):
    pass


class STTFailed(Exception):
    pass


class STTNoSpeech(STTFailed):
    pass


class TranscriptionProvider(Protocol):
    async def transcribe_wav(self, audio: bytes) -> str: ...


class DashScopeTranscriptionProvider:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    async def transcribe_wav(self, audio: bytes) -> str:
        return await asyncio.to_thread(self._transcribe_sync, audio)

    def _transcribe_sync(self, audio: bytes) -> str:
        if not self.settings.dashscope_api_key:
            raise STTNotConfigured

        try:
            with wave.open(io.BytesIO(audio), "rb") as wav:
                if wav.getnchannels() != 1 or wav.getsampwidth() != 2:
                    raise STTFailed("Use mono 16-bit PCM WAV audio.")
                sample_rate = wav.getframerate()
                if sample_rate != 16000:
                    raise STTFailed("Use 16 kHz WAV audio.")
                if not wav.readframes(wav.getnframes()):
                    raise STTFailed("Audio is empty.")
        except (wave.Error, EOFError) as exc:
            raise STTFailed("Invalid WAV audio.") from exc

        audio_data = "data:audio/wav;base64," + base64.b64encode(audio).decode("ascii")
        body = {
            "model": self.settings.stt_model,
            "input": {
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "input_audio",
                                "input_audio": {"data": audio_data},
                            }
                        ],
                    }
                ]
            },
            "parameters": {"format": "wav", "sample_rate": "16000"},
        }

        transcript = ""
        try:
            with Client(
                api_key=self.settings.dashscope_api_key,
                region=self.settings.dashscope_region,
                workspace=self.settings.dashscope_workspace,
                timeout=self.settings.stt_timeout_seconds,
                max_retries=0,
            ) as client:
                response = client.transport.open_stream(
                    "POST",
                    "/services/aigc/multimodal-generation/generation",
                    json=body,
                    headers={"X-DashScope-SSE": "enable"},
                    timeout=self.settings.stt_timeout_seconds,
                    sdk_module="audio",
                )
                try:
                    for line in response.iter_lines():
                        if not line.startswith("data:"):
                            continue
                        raw = line[5:].strip()
                        if not raw or raw == "[DONE]":
                            continue
                        event = json.loads(raw)
                        if not isinstance(event, dict):
                            raise STTFailed("Invalid transcription event.")
                        if event.get("code"):
                            raise STTFailed("Speech transcription failed.")
                        output = event.get("output")
                        if isinstance(output, dict) and isinstance(output.get("text"), str):
                            transcript = output["text"]
                finally:
                    response.close()
        except STTFailed:
            raise
        except BadRequestError as exc:
            if "ASR_RESPONSE_HAVE_NO_WORDS" in str(exc):
                raise STTNoSpeech("No speech was recognized.") from exc
            raise STTFailed("Speech transcription failed.") from exc
        except Exception as exc:
            raise STTFailed("Speech transcription failed.") from exc

        transcript = transcript.strip()
        if not transcript:
            raise STTNoSpeech("No speech was recognized.")
        return transcript


def get_transcription_provider() -> TranscriptionProvider:
    return DashScopeTranscriptionProvider(get_settings())
