from typing import Literal

from pydantic import BaseModel, Field


class AudioTrackOut(BaseModel):
    url: str | None = None
    status: Literal["ready", "unavailable"] = "unavailable"


class AudioOut(BaseModel):
    us: AudioTrackOut = Field(default_factory=AudioTrackOut)
    uk: AudioTrackOut = Field(default_factory=AudioTrackOut)


class SpeechAudioOut(BaseModel):
    url: str | None = None
    status: Literal["ready", "unavailable"] = "unavailable"


class PronunciationRequest(BaseModel):
    text: str = Field(min_length=1, max_length=200)
