from datetime import date

from pydantic import BaseModel, ConfigDict, Field

from tts.schemas import SpeechAudioOut


class TimedWordOut(BaseModel):
    text: str
    start_char: int
    end_char: int
    begin_ms: int
    end_ms: int


class DailyReadAgentOutput(BaseModel):
    model_config = ConfigDict(extra="ignore")

    title: str = Field(min_length=1, max_length=200)
    passage: str = Field(min_length=40, max_length=3000)
    target_words: list[str] = Field(default_factory=list, max_length=8)
    question: str | None = Field(default=None, max_length=500)


class DailyReadOut(BaseModel):
    date: date
    title: str
    passage: str
    target_words: list[str]
    question: str | None
    audio: SpeechAudioOut
    words: list[TimedWordOut] = Field(default_factory=list)
    completed: bool = False
    streak: int = 0
    duration_seconds: int | None = None


class DailyCompleteIn(BaseModel):
    duration_seconds: int | None = Field(default=None, ge=0, le=3600)


class DailyCompleteOut(BaseModel):
    date: date
    completed: bool
    streak: int
    word_count: int
    target_words: list[str]
    duration_seconds: int | None = None


class DailyTranslationAgentOutput(BaseModel):
    translations: list[str] = Field(min_length=1, max_length=30)


class DailyTranslationLineOut(BaseModel):
    text: str
    start_char: int
    end_char: int
    translation: str


class DailyTranslationOut(BaseModel):
    language: str
    lines: list[DailyTranslationLineOut]
