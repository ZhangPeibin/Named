from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

CompanionGender = Literal["female", "male", "prefer_not_to_say"]


class CompanionOut(BaseModel):
    name: str | None
    gender: CompanionGender | None
    hobby: str | None
    avatar_key: str
    voice_key: str
    setup_dismissed: bool
    updated_at: datetime


class CompanionUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=64)
    gender: CompanionGender | None = None
    hobby: str | None = Field(default=None, max_length=255)
    setup_dismissed: bool | None = None


class NameSuggestionOut(BaseModel):
    name: str
