from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class InitialSoul(BaseModel):
    native_language: str = Field(min_length=2, max_length=32)
    age: int | None = Field(default=None, ge=0, le=120)
    gender: str | None = Field(default=None, max_length=32)
    interests: list[str] = Field(default_factory=list, max_length=50)


class SoulProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    native_language: str
    age: int | None
    gender: str | None
    updated_at: datetime


class SoulItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    kind: str
    text: str
    source: str
    created_at: datetime
    updated_at: datetime


class SoulResponse(BaseModel):
    profile: SoulProfileOut
    items: list[SoulItemOut]


class SoulUpdate(BaseModel):
    native_language: str | None = Field(default=None, min_length=2, max_length=32)
    age: int | None = Field(default=None, ge=0, le=120)
    gender: str | None = Field(default=None, max_length=32)


class SoulItemCreate(BaseModel):
    kind: str = Field(min_length=1, max_length=32)
    text: str = Field(min_length=1, max_length=500)


class SoulItemUpdate(BaseModel):
    kind: str | None = Field(default=None, min_length=1, max_length=32)
    text: str | None = Field(default=None, min_length=1, max_length=500)
