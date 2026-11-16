from datetime import datetime

from pydantic import BaseModel, Field


class QuestionAskIn(BaseModel):
    text: str = Field(min_length=1, max_length=2000)


class QuestionAgentOutput(BaseModel):
    answer: str = Field(min_length=1, max_length=4000)
    native_explanation: str = Field(min_length=1, max_length=4000)


class QuestionOut(BaseModel):
    id: str
    question: str
    answer: str
    native_explanation: str
    created_at: datetime


class QuestionListOut(BaseModel):
    items: list[QuestionOut]
