from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class ExperienceCandidate(BaseModel):
    summary: str = Field(min_length=1, max_length=2000)
    detail: str | None = Field(default=None, max_length=4000)
    evidence_sequences: list[int] = Field(default_factory=list, max_length=12)
    related_terms: list[str] = Field(default_factory=list, max_length=8)
    confidence: float = Field(default=0.0, ge=0, le=1)


class ExperienceExtraction(BaseModel):
    life: ExperienceCandidate | None = None
    learning: ExperienceCandidate | None = None


class ExperienceSourceOut(BaseModel):
    source_type: str
    source_id: str
    quote: str | None = None


class ExperienceListItem(BaseModel):
    id: str
    kind: Literal["life", "learning"]
    summary: str
    detail: str | None = None
    confidence: float
    created_at: datetime
    focus_type: str
    focus_id: str
    focus_title: str
    conversation_id: str


class ExperienceListOut(BaseModel):
    items: list[ExperienceListItem]
    next_cursor: str | None = None


class ExperienceDetailOut(ExperienceListItem):
    sources: list[ExperienceSourceOut] = Field(default_factory=list)
