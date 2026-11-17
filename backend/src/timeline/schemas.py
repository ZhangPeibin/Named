from datetime import date, datetime
from typing import Annotated, Literal

from pydantic import BaseModel, Field

from discovery.schemas import ScenePayload, WordPayload
from tts.schemas import AudioOut, SpeechAudioOut


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


class TimelineSceneItem(BaseModel):
    type: Literal["scene"] = "scene"
    id: str
    created_at: datetime
    input_text: str | None
    input_language: str | None
    scene: ScenePayload
    audio: SpeechAudioOut | None = None
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


class TimelineDailyItem(BaseModel):
    type: Literal["daily"] = "daily"
    id: str
    created_at: datetime
    reading_date: date
    title: str | None = None
    completed: bool = False
    word_count: int = 0
    streak: int = 0


class TimelineQuestionItem(BaseModel):
    type: Literal["question"] = "question"
    id: str
    created_at: datetime
    title: str
    last_text: str = ""
    context_type: str | None = None


TimelineItem = Annotated[
    TimelineWordItem
    | TimelineSceneItem
    | TimelineTalkItem
    | TimelineDailyItem
    | TimelineQuestionItem,
    Field(discriminator="type"),
]


class TimelineResponse(BaseModel):
    items: list[TimelineItem]
    next_cursor: str | None = None
