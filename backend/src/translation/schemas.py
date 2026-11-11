from typing import Literal

from pydantic import BaseModel, Field


class TranslationRequest(BaseModel):
    text: str = Field(min_length=1, max_length=1000)


class TranslationAgentOutput(BaseModel):
    translated_text: str = Field(min_length=1, max_length=2000)


class TranslationOut(BaseModel):
    source_language: Literal["en", "zh"]
    target_language: Literal["en", "zh"]
    translated_text: str
