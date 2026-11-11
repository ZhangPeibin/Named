from typing import Annotated

from fastapi import APIRouter, File, UploadFile

from auth.router import CurrentAuthDep
from errors import ApiError
from ratelimit import TalkRateLimitDep
from stt.deps import TranscriptionProviderDep
from stt.provider import STTFailed, STTNoSpeech, STTNotConfigured
from stt.schemas import TranscriptionOut

router = APIRouter(prefix="/audio", tags=["audio"])


@router.post("/transcribe", response_model=TranscriptionOut)
async def transcribe(
    current: CurrentAuthDep,
    provider: TranscriptionProviderDep,
    _: TalkRateLimitDep,
    file: Annotated[UploadFile, File()],
) -> TranscriptionOut:
    audio = await file.read()
    if not audio:
        raise ApiError("Audio is empty.", code="audio_empty")
    if len(audio) > 10 * 1024 * 1024:
        raise ApiError("Audio is too large.", code="audio_too_large")

    try:
        text = await provider.transcribe_wav(audio)
    except STTNotConfigured as exc:
        raise ApiError(
            "Speech recognition is not configured.",
            status_code=503,
            code="stt_not_configured",
        ) from exc
    except STTNoSpeech as exc:
        raise ApiError(
            "No speech was recognized.",
            status_code=422,
            code="no_speech",
        ) from exc
    except STTFailed as exc:
        raise ApiError(
            "Could not recognize speech.",
            status_code=502,
            code="stt_failed",
        ) from exc
    return TranscriptionOut(text=text)
