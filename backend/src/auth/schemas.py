from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from soul.schemas import InitialSoul, SoulResponse


class AuthCodeRequest(BaseModel):
    email: EmailStr


class AuthCodeResponse(BaseModel):
    expires_in: int
    resend_after: int


class VerifyRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")
    initial_soul: InitialSoul | None = None


class AccountOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    created_at: datetime


class VerifyResponse(BaseModel):
    session_token: str
    account: AccountOut
    soul: SoulResponse
    is_new: bool


class AccountDeletionOut(BaseModel):
    status: Literal["deletion_scheduled"] = "deletion_scheduled"
    deletion_scheduled_at: datetime
