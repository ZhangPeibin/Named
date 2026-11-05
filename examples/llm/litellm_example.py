"""LiteLLM example.

LiteLLM is a multi-provider gateway. It gives you one HTTP interface for
DeepSeek, OpenAI, Anthropic and many others, but it does not define your agent:
you still write the prompt, parse the JSON, validate it and retry.

Run:
    uv run litellm_example.py 树
    uv run litellm_example.py --mock 树
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os

from dotenv import load_dotenv
from litellm import acompletion
from pydantic import BaseModel, ValidationError

load_dotenv()

SYSTEM_PROMPT = """
You are a vocabulary assistant for an English learning app.
The user gives a word, phrase or short situation in any language.
Return ONE JSON object with exactly these fields:
{
  "word": "English word or phrase",
  "translation_zh": "Chinese translation",
  "part_of_speech": "noun / verb / adjective / phrase ...",
  "definition_en": "one simple English sentence",
  "example_en": "one natural English example sentence"
}
Return JSON only. Do not wrap it in markdown.
""".strip()


class WordInfo(BaseModel):
    word: str
    translation_zh: str
    part_of_speech: str
    definition_en: str
    example_en: str


async def call_model(text: str) -> str:
    model = os.getenv("LITELLM_MODEL", "deepseek/deepseek-flash")
    response = await acompletion(
        model=model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        response_format={"type": "json_object"},
        temperature=0,
    )
    return response.choices[0].message.content or ""


async def run(text: str) -> WordInfo:
    raw = await call_model(text)
    try:
        return WordInfo.model_validate(json.loads(raw))
    except (json.JSONDecodeError, ValidationError) as exc:
        raise SystemExit(f"Model returned invalid data: {exc}\nRaw output:\n{raw}") from exc


def mock() -> WordInfo:
    return WordInfo(
        word="tree",
        translation_zh="树",
        part_of_speech="noun",
        definition_en="a tall plant with a trunk and branches",
        example_en="There is a tree in the park.",
    )


async def main() -> None:
    parser = argparse.ArgumentParser(description="LiteLLM structured-output example")
    parser.add_argument("text", nargs="?", default="树", help="word or phrase to analyze")
    parser.add_argument("--mock", action="store_true", help="run offline with fake data")
    args = parser.parse_args()

    try:
        info = mock() if args.mock else await run(args.text)
    except SystemExit:
        raise
    except Exception as exc:
        raise SystemExit(f"Model call failed: {exc}") from exc

    print(info.model_dump_json(indent=2))


if __name__ == "__main__":
    asyncio.run(main())
