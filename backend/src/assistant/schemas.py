from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

AssistantIntent = Literal[
    "review_words",
    "start_challenge",
    "view_challenges",
    "none",
]


class AssistantIntentRequest(BaseModel):
    text: str = Field(min_length=1, max_length=1000)


class AssistantIntentOut(BaseModel):
    model_config = ConfigDict(extra="ignore")

    intent: AssistantIntent
    confidence: float = Field(ge=0, le=1)
