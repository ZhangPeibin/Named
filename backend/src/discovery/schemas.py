from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from tts.schemas import AudioOut, SpeechAudioOut


class WordCandidate(BaseModel):
    model_config = ConfigDict(extra="ignore")

    label_en: str = Field(min_length=1, max_length=200)
    label_zh: str = Field(min_length=1, max_length=200)
    confidence: float = Field(ge=0, le=1)
    reason: str = Field(min_length=1, max_length=500)


class DiscoveryFocus(BaseModel):
    model_config = ConfigDict(extra="ignore")

    kind: Literal["word", "scene"]
    label_en: str = Field(min_length=1, max_length=200)
    label_zh: str = Field(min_length=1, max_length=200)
    confidence: float = Field(ge=0, le=1)


class WordSense(BaseModel):
    model_config = ConfigDict(extra="ignore")

    definition_en: str = Field(min_length=1, max_length=1000)
    definition_zh: str = Field(min_length=1, max_length=1000)
    example_en: str = Field(min_length=1, max_length=1000)
    example_zh: str = Field(min_length=1, max_length=1000)


class WordChunk(BaseModel):
    model_config = ConfigDict(extra="ignore")

    phrase: str = Field(min_length=1, max_length=300)
    meaning_zh: str = Field(min_length=1, max_length=500)
    example_en: str = Field(min_length=1, max_length=1000)


class VarietyNote(BaseModel):
    model_config = ConfigDict(extra="ignore")

    kind: Literal["vocabulary", "spelling", "pronunciation", "usage"]
    description_zh: str = Field(min_length=1, max_length=1000)
    us: str | None = Field(default=None, max_length=500)
    uk: str | None = Field(default=None, max_length=500)
    example_en: str | None = Field(default=None, max_length=1000)


class SceneExtension(BaseModel):
    model_config = ConfigDict(extra="ignore")

    label_en: str = Field(min_length=1, max_length=200)
    label_zh: str = Field(default="", max_length=200)
    relationship: str = Field(default="", max_length=500)


class WordPayload(BaseModel):
    model_config = ConfigDict(extra="ignore")

    spelling: str = Field(min_length=1, max_length=200)
    ipa: dict[str, str] = Field(default_factory=dict)
    pos: list[str] = Field(default_factory=list)
    senses: list[WordSense] = Field(default_factory=list, min_length=1, max_length=3)
    grammar: str = ""
    related: list[str] = Field(default_factory=list)
    chunks: list[WordChunk] = Field(default_factory=list, max_length=5)
    variety_notes: list[VarietyNote] = Field(default_factory=list, max_length=4)
    scene_extensions: list[SceneExtension] = Field(default_factory=list, max_length=6)

    @field_validator("scene_extensions", mode="before")
    @classmethod
    def normalize_legacy_scene_extensions(cls, value):
        if not value:
            return []
        normalized = []
        for item in value:
            if isinstance(item, str):
                normalized.append({"label_en": item, "label_zh": "", "relationship": ""})
            else:
                normalized.append(item)
        return normalized


class SceneChunk(BaseModel):
    model_config = ConfigDict(extra="ignore")

    phrase: str = Field(min_length=1, max_length=300)
    meaning_native: str = Field(min_length=1, max_length=500)
    example_en: str | None = Field(default=None, max_length=1000)


class SceneCorrection(BaseModel):
    model_config = ConfigDict(extra="ignore")

    original: str = Field(min_length=1, max_length=2000)
    suggestion: str = Field(min_length=1, max_length=2000)
    note: str = Field(min_length=1, max_length=1000)


class ScenePayload(BaseModel):
    model_config = ConfigDict(extra="ignore")

    natural_english: str = Field(min_length=1, max_length=2000)
    key_chunks: list[SceneChunk] = Field(default_factory=list, max_length=3)
    key_words: list[str] = Field(default_factory=list, max_length=5)
    correction: SceneCorrection | None = None


class DiscoveryAgentOutput(BaseModel):
    model_config = ConfigDict(extra="ignore")

    input_language: str = Field(min_length=2, max_length=16)
    focus: DiscoveryFocus
    word: WordPayload | None = None
    scene: ScenePayload | None = None
    warnings: list[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def require_focus_payload(self) -> "DiscoveryAgentOutput":
        if self.focus.kind == "word" and self.word is None:
            raise ValueError("word is required when focus.kind is 'word'")
        if self.focus.kind == "scene" and self.scene is None:
            raise ValueError("scene is required when focus.kind is 'scene'")
        return self


class CandidateOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    label_en: str
    label_zh: str
    confidence: float
    reason: str
    selected: bool


class DiscoveryOut(BaseModel):
    id: str
    input_type: str
    input_text: str | None
    context: str | None
    image_url: str | None = None
    input_language: str | None
    status: Literal["needs_confirmation", "ready"]
    focus_kind: str | None
    word_id: str | None
    candidates: list[CandidateOut]
    word: WordPayload | None
    scene: ScenePayload | None = None
    audio: AudioOut | None = None
    scene_audio: SpeechAudioOut | None = None
    needs_confirmation: bool
    warnings: list[str] = Field(default_factory=list)


class FocusRequest(BaseModel):
    candidate_id: str | None = None
    label_en: str | None = None
    whole_scene: bool = False

    @model_validator(mode="after")
    def require_exactly_one_choice(self) -> "FocusRequest":
        choices = [
            self.candidate_id is not None,
            self.label_en is not None,
            self.whole_scene,
        ]
        if sum(choices) != 1:
            raise ValueError("Provide exactly one of candidate_id, label_en, or whole_scene")
        return self


class WordOut(BaseModel):
    id: str
    label_en: str
    content: WordPayload | None
    audio: AudioOut | None = None


WordStatus = Literal["needs_review", "growing", "known"]


class WordListItem(BaseModel):
    id: str
    label_en: str
    content: WordPayload | None = None
    audio: AudioOut | None = None
    discovery_count: int = 1
    first_seen_at: datetime
    last_seen_at: datetime
    status: WordStatus = "needs_review"
    review_count: int = 0
    last_reviewed_at: datetime | None = None


class WordsStats(BaseModel):
    total: int
    new_this_week: int
    reviewed_this_week: int
    used_in_talk_this_week: int


class WordsResponse(BaseModel):
    stats: WordsStats
    words: list[WordListItem]


class WordProgressUpdate(BaseModel):
    known: bool


class WordProgressOut(BaseModel):
    word_id: str
    status: WordStatus
    review_count: int
    last_reviewed_at: datetime | None = None


class TalkWordSave(BaseModel):
    label: str = Field(min_length=1, max_length=200)
    meaning_zh: str = Field(min_length=1, max_length=1000)
    part_of_speech: str | None = Field(default=None, max_length=32)
    grammar: str | None = Field(default=None, max_length=500)
    example_en: str | None = Field(default=None, max_length=1000)


class WordSaveOut(BaseModel):
    word_id: str
    label: str
    created: bool
