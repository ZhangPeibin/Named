from pydantic import BaseModel


class ProgressOut(BaseModel):
    words: int
    conversations: int
    readings: int
