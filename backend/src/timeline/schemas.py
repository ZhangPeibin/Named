from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, Field

from discovery.schemas import WordPayload
from tts.schemas import AudioOut


class TimelineWordItem(BaseModel):
    type: Literal["word"] = "word"
    id: str
    created_at: datetime
    input_text: str | None
    status: str
    focus_kind: str | None
    word_id: str | None
    word: WordPayload | None
    audio: AudioOut | None = None
    conversation_id: str | None = None


class TimelineTalkMessage(BaseModel):
    role: str
    text: str
    created_at: datetime


class TimelineTalkItem(BaseModel):
    type: Literal["talk"] = "talk"
    id: str
    created_at: datetime
    conversation_id: str
    title: str
    focus_type: str
    focus_id: str
    last_message: TimelineTalkMessage
    message_count: int


TimelineItem = Annotated[
    TimelineWordItem | TimelineTalkItem,
    Field(discriminator="type"),
]


class TimelineResponse(BaseModel):
    items: list[TimelineItem]
    next_cursor: str | None = None
