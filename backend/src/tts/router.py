from fastapi import APIRouter, Response

from auth.router import CurrentAuthDep
from errors import ApiError
from tts.deps import MediaStoreDep

audio_router = APIRouter(prefix="/audio", tags=["audio"])


def _media_type(key: str) -> str:
    if key.endswith(".mp3"):
        return "audio/mpeg"
    if key.endswith(".wav"):
        return "audio/wav"
    if key.endswith(".ogg"):
        return "audio/ogg"
    return "application/octet-stream"


@audio_router.get("/{key:path}")
async def read_audio(
    key: str,
    current: CurrentAuthDep,
    store: MediaStoreDep,
) -> Response:
    data = await store.get(key)
    if data is None:
        raise ApiError("Audio not found.", status_code=404, code="audio_not_found")
    return Response(
        content=data,
        media_type=_media_type(key),
        headers={"Cache-Control": "private, max-age=86400"},
    )
