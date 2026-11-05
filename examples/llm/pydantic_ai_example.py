"""Pydantic AI example.

Pydantic AI is an agent framework. You declare the output type once, and the
framework builds the structured-output request, validates the result with
Pydantic, and retries when the model returns invalid data.

Run:
    uv run pydantic_ai_example.py 树
    uv run pydantic_ai_example.py --mock 树
"""

from __future__ import annotations

import argparse
import asyncio
import os

from dotenv import load_dotenv
from pydantic import BaseModel, Field
from pydantic_ai import Agent
from pydantic_ai.exceptions import ModelAPIError, UserError
from pydantic_ai.models.openai import OpenAIChatModelSettings
from pydantic_ai.models.test import TestModel

load_dotenv()

SYSTEM_PROMPT = """
You are a vocabulary assistant for an English learning app.
The user gives a word, phrase or short situation in any language.
Give the most useful English word or phrase, a Chinese translation, its part of
speech, a simple English definition, and one natural example sentence.
""".strip()


class WordInfo(BaseModel):
    word: str = Field(description="English word or phrase")
    translation_zh: str = Field(description="Chinese translation")
    part_of_speech: str = Field(description="noun, verb, adjective, phrase, ...")
    definition_en: str = Field(description="one simple English sentence")
    example_en: str = Field(description="one natural English example sentence")


def build_agent(model_name: str) -> Agent:
    # DeepSeek V4 thinks by default and rejects a forced tool choice while
    # thinking is on. Disable thinking so structured output is reliable.
    settings = (
        OpenAIChatModelSettings(thinking=False) if model_name.startswith("deepseek:") else None
    )
    return Agent(
        model_name,
        output_type=WordInfo,
        system_prompt=SYSTEM_PROMPT,
        model_settings=settings,
    )


def build_mock_agent() -> Agent:
    return Agent(
        TestModel(
            custom_output_args={
                "word": "tree",
                "translation_zh": "树",
                "part_of_speech": "noun",
                "definition_en": "a tall plant with a trunk and branches",
                "example_en": "There is a tree in the park.",
            }
        ),
        output_type=WordInfo,
    )


async def main() -> None:
    parser = argparse.ArgumentParser(description="Pydantic AI structured-output example")
    parser.add_argument("text", nargs="?", default="树", help="word or phrase to analyze")
    parser.add_argument("--mock", action="store_true", help="run offline with TestModel")
    args = parser.parse_args()

    try:
        if args.mock:
            agent = build_mock_agent()
        else:
            agent = build_agent(os.getenv("PYDANTIC_AI_MODEL", "deepseek:deepseek-flash"))

        result = await agent.run(args.text)
    except (UserError, ModelAPIError) as exc:
        raise SystemExit(f"Model call failed: {exc}") from exc

    print(result.output.model_dump_json(indent=2))


if __name__ == "__main__":
    asyncio.run(main())
