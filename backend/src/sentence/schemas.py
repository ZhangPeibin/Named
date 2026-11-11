from pydantic import BaseModel, Field


class SentenceChunk(BaseModel):
    phrase: str = Field(min_length=1, max_length=300)
    meaning_native: str = Field(min_length=1, max_length=500)
    example_en: str | None = Field(default=None, max_length=1000)


class SentenceKeyWord(BaseModel):
    word: str = Field(min_length=1, max_length=200)
    part_of_speech: str | None = Field(default=None, max_length=32)
    meaning_native: str = Field(min_length=1, max_length=500)


class SentenceAgentOutput(BaseModel):
    natural_english: str = Field(min_length=1, max_length=2000)
    explanation_native: str = Field(min_length=1, max_length=2000)
    grammar_notes: str = Field(default="", max_length=2000)
    chunks: list[SentenceChunk] = Field(default_factory=list, max_length=6)
    key_words: list[SentenceKeyWord] = Field(default_factory=list, max_length=8)


class SentenceLookupRequest(BaseModel):
    text: str = Field(min_length=1, max_length=2000)


class SentenceOut(BaseModel):
    original: str
    natural_english: str
    explanation_native: str
    grammar_notes: str = ""
    chunks: list[SentenceChunk] = Field(default_factory=list)
    key_words: list[SentenceKeyWord] = Field(default_factory=list)
