from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from tts.schemas import SpeechAudioOut


class Correction(BaseModel):
    original: str = Field(min_length=1, max_length=2000)
    suggestion: str = Field(min_length=1, max_length=2000)
    note: str = Field(min_length=1, max_length=1000)


class Annotation(BaseModel):
    text: str = Field(min_length=1, max_length=200)
    kind: Literal["word", "expression"]
    meaning_zh: str = Field(min_length=1, max_length=500)


class TalkResponse(BaseModel):
    reply: str = Field(min_length=1, max_length=4000)
    native_reply: str | None = Field(default=None, max_length=4000)
    corrections: list[Correction] = Field(default_factory=list)
    annotations: list[Annotation] = Field(default_factory=list)
    suggested_expressions: list[str] = Field(default_factory=list)
    needs_confirmation: bool = False


class HelpRequest(BaseModel):
    text: str = Field(min_length=1, max_length=1000)


class HelpSuggestion(BaseModel):
    natural_english: str = Field(min_length=1, max_length=1000)
    note: str | None = Field(default=None, max_length=500)
    alternatives: list[str] = Field(default_factory=list, max_length=2)


class HelpResponse(BaseModel):
    natural_english: str
    note: str | None = None
    alternatives: list[str] = Field(default_factory=list)
    audio: SpeechAudioOut | None = None


class ConversationCreate(BaseModel):
    focus_type: Literal["word", "scene"]
    focus_id: str = Field(min_length=1, max_length=36)


class MessageCreate(BaseModel):
    client_message_id: str = Field(min_length=1, max_length=64)
    text: str = Field(min_length=1, max_length=2000)
    source: Literal["text", "voice"] = "text"
    transcript_confidence: float | None = Field(default=None, ge=0, le=1)
    transcript_confirmed: bool = True


class CorrectionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    original: str
    suggestion: str
    note: str


class AnnotationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    text: str
    kind: str
    meaning_zh: str


class MessageOut(BaseModel):
    id: str
    role: str
    text: str
    native_text: str | None = None
    source: str
    transcript_state: str
    status: str
    audio: SpeechAudioOut | None = None
    corrections: list[CorrectionOut] = Field(default_factory=list)
    annotations: list[AnnotationOut] = Field(default_factory=list)
    created_at: datetime


class ConversationOut(BaseModel):
    id: str
    title: str
    focus_type: str
    focus_id: str
    status: str
    started_at: datetime
    ended_at: datetime | None
    messages: list[MessageOut]


class TurnOut(BaseModel):
    user_message: MessageOut
    assistant_message: MessageOut
    save_status: Literal["saved"] = "saved"


class EndConversationOut(BaseModel):
    id: str
    status: str
    ended_at: datetime | None
