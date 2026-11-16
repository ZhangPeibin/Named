from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class QuestionContextIn(BaseModel):
    type: Literal["word", "sentence", "reading", "talk", "none"] = "none"
    ref: str | None = Field(default=None, max_length=64)
    quote: str | None = Field(default=None, max_length=2000)


class QuestionAskIn(BaseModel):
    text: str = Field(min_length=1, max_length=2000)
    context: QuestionContextIn | None = None


class QuestionFollowUpIn(BaseModel):
    text: str = Field(min_length=1, max_length=2000)


class QuestionAgentOutput(BaseModel):
    answer: str = Field(min_length=1, max_length=4000)
    example: str | None = Field(default=None, max_length=1200)
    native_explanation: str = Field(min_length=1, max_length=4000)
    confidence: Literal["high", "medium", "low"] = "high"
    follow_up_suggestions: list[str] = Field(default_factory=list, max_length=2)


class QuestionMessageOut(BaseModel):
    id: str
    role: str
    text: str
    example: str | None = None
    native_explanation: str | None = None
    confidence: str | None = None
    created_at: datetime


class QuestionThreadOut(BaseModel):
    id: str
    title: str
    context_type: str | None = None
    context_ref: str | None = None
    context_quote: str | None = None
    messages: list[QuestionMessageOut] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class QuestionThreadSummaryOut(BaseModel):
    id: str
    title: str
    context_type: str | None = None
    context_quote: str | None = None
    last_text: str = ""
    updated_at: datetime


class QuestionThreadListOut(BaseModel):
    items: list[QuestionThreadSummaryOut]
