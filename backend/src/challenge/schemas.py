from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class ChallengeCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    planned_days: int = Field(ge=1, le=365)
    discovery_ids: list[str] = Field(min_length=1, max_length=50)


class ChallengeItemOut(BaseModel):
    id: str
    discovery_id: str
    position: int
    visited_at: datetime | None
    focus_type: Literal["word", "scene"]
    focus_id: str
    title: str
    subtitle: str | None = None


class ChallengeOut(BaseModel):
    id: str
    name: str
    planned_days: int
    status: Literal["active", "ended"]
    started_at: datetime
    ended_at: datetime | None
    created_at: datetime
    total_count: int
    visited_count: int
    is_due: bool
    items: list[ChallengeItemOut]


class ChallengeListOut(BaseModel):
    items: list[ChallengeOut]
