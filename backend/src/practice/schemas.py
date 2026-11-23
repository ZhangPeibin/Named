from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from discovery.schemas import WordPayload
from tts.schemas import AudioOut


class PracticeWordOut(BaseModel):
    id: str
    label_en: str
    content: WordPayload | None = None
    audio: AudioOut | None = None
    context: str | None = None
    options: list[str] = Field(default_factory=list)
    practice_count: int = 0


class PracticeCompleteOut(BaseModel):
    word_id: str
    practice_count: int
    last_practiced_at: datetime | None = None


class PracticeMessage(BaseModel):
    role: Literal["learner", "assistant"]
    text: str = Field(min_length=1, max_length=1000)


class PracticeReplyIn(BaseModel):
    text: str = Field(min_length=1, max_length=1000)
    history: list[PracticeMessage] = Field(default_factory=list, max_length=10)


class PracticeReplyOut(BaseModel):
    reply: str = Field(min_length=1, max_length=1000)
    recast: str | None = Field(default=None, max_length=1000)
    native_reply: str | None = Field(default=None, max_length=1000)
