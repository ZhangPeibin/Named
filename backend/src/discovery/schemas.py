from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from tts.schemas import AudioOut


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


class WordPayload(BaseModel):
    model_config = ConfigDict(extra="ignore")

    spelling: str = Field(min_length=1, max_length=200)
    ipa: dict[str, str] = Field(default_factory=dict)
    pos: list[str] = Field(default_factory=list)
    senses: list[WordSense] = Field(default_factory=list, min_length=1, max_length=3)
    grammar: str = ""
    related: list[str] = Field(default_factory=list)
    scene_extensions: list[str] = Field(default_factory=list)


class DiscoveryAgentOutput(BaseModel):
    model_config = ConfigDict(extra="ignore")

    input_language: str = Field(min_length=2, max_length=16)
    focus: DiscoveryFocus
    candidates: list[WordCandidate] = Field(min_length=1, max_length=5)
    word: WordPayload | None = None
    needs_confirmation: bool = False
    warnings: list[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def require_word_for_word_focus(self) -> "DiscoveryAgentOutput":
        if self.focus.kind == "word" and self.word is None:
            raise ValueError("word is required when focus.kind is 'word'")
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
    audio: AudioOut | None = None
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
