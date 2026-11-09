from __future__ import annotations

import hashlib
import math
import re
from datetime import datetime

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from models import MemoryItem
from talk.schemas import Correction, MemoryCandidate

TYPE_WEIGHTS = {
    "identity": 1.0,
    "learning_error": 0.95,
    "word": 0.8,
    "expression": 0.75,
    "experience": 0.7,
    "preference": 0.65,
    "topic": 0.55,
}
HALF_LIFE_DAYS = {
    "identity": 365.0,
    "learning_error": 30.0,
    "word": 90.0,
    "expression": 60.0,
    "experience": 180.0,
    "preference": 120.0,
    "topic": 21.0,
}
MAX_MEMORY_RESULTS = 8
MAX_MEMORY_CONTEXT_CHARS = 1800
MAX_CANDIDATE_ROWS = 200


def _canonical_key(kind: str, text: str) -> str:
    normalized = " ".join(text.strip().lower().split())
    return hashlib.sha256(f"{kind}:{normalized}".encode()).hexdigest()


def _clean_text(text: str) -> str:
    return " ".join(text.split())[:500]


def correction_candidates(corrections: list[Correction]) -> list[MemoryCandidate]:
    return [
        MemoryCandidate(
            kind="learning_error",
            text=_clean_text(f"{correction.original} -> {correction.suggestion}"),
            confidence=0.95,
            importance=0.8,
        )
        for correction in corrections
        if correction.original.strip() and correction.suggestion.strip()
    ]


async def record_memories(
    session: AsyncSession,
    account_id: str,
    candidates: list[MemoryCandidate],
    *,
    source_type: str,
    source_id: str,
    now: datetime | None = None,
) -> list[MemoryItem]:
    current_time = now or utcnow()
    prepared: list[tuple[MemoryCandidate, str]] = []
    keys: set[str] = set()
    for candidate in candidates:
        text = _clean_text(candidate.text)
        if not text:
            continue
        key = _canonical_key(candidate.kind, text)
        if key in keys:
            continue
        prepared.append((candidate, text))
        keys.add(key)

    if not prepared:
        return []

    rows = await session.scalars(
        select(MemoryItem).where(
            MemoryItem.account_id == account_id,
            MemoryItem.canonical_key.in_(keys),
        )
    )
    existing = {row.canonical_key: row for row in rows}
    recorded: list[MemoryItem] = []
    for candidate, text in prepared:
        key = _canonical_key(candidate.kind, text)
        row = existing.get(key)
        if row is not None:
            if row.deleted_at is not None:
                continue
            row.text = text
            row.source_type = source_type
            row.source_id = source_id
            row.confidence = max(row.confidence, candidate.confidence)
            row.importance = max(row.importance, candidate.importance)
            row.mention_count += 1
            row.last_seen_at = current_time
            row.expires_at = None
            recorded.append(row)
            continue

        row = MemoryItem(
            account_id=account_id,
            kind=candidate.kind,
            text=text,
            canonical_key=key,
            source_type=source_type,
            source_id=source_id,
            confidence=candidate.confidence,
            importance=candidate.importance,
            mention_count=1,
            first_seen_at=current_time,
            last_seen_at=current_time,
        )
        session.add(row)
        recorded.append(row)

    await session.flush()
    return recorded


def _tokens(text: str) -> set[str]:
    raw = re.findall(r"[a-z0-9']+|[\u4e00-\u9fff]+", text.lower())
    tokens: set[str] = set()
    for token in raw:
        if re.fullmatch(r"[\u4e00-\u9fff]+", token):
            if len(token) == 1:
                tokens.add(token)
            else:
                tokens.update(token[index : index + 2] for index in range(len(token) - 1))
        else:
            tokens.add(token)
    return tokens


def score_memory(
    memory: MemoryItem,
    *,
    query_tokens: set[str],
    now: datetime,
) -> float:
    memory_tokens = _tokens(memory.text)
    if not query_tokens:
        relevance = 0.5
    else:
        overlap = len(memory_tokens & query_tokens)
        relevance = (
            0.2
            if overlap == 0
            else min(1.0, 0.2 + 0.8 * overlap / max(1, min(len(memory_tokens), 8)))
        )

    last_seen = memory.last_seen_at or memory.created_at
    age_days = max(0.0, (now - last_seen).total_seconds() / 86400)
    half_life = HALF_LIFE_DAYS.get(memory.kind, 60.0)
    recency = math.exp(-math.log(2) * age_days / half_life)
    frequency = 1.0 + math.log1p(max(0, memory.mention_count))
    type_weight = TYPE_WEIGHTS.get(memory.kind, 0.5)
    importance = 0.5 + max(0.0, min(1.0, memory.importance))
    confidence = 0.5 + 0.5 * max(0.0, min(1.0, memory.confidence))
    return type_weight * recency * frequency * relevance * importance * confidence


def rank_memories(
    memories: list[MemoryItem],
    *,
    focus_context: str = "",
    user_text: str = "",
    now: datetime | None = None,
) -> list[MemoryItem]:
    current_time = now or utcnow()
    query_tokens = _tokens(f"{focus_context} {user_text}")
    return sorted(
        memories,
        key=lambda memory: score_memory(
            memory,
            query_tokens=query_tokens,
            now=current_time,
        ),
        reverse=True,
    )


async def get_memory_context(
    session: AsyncSession,
    account_id: str,
    *,
    focus_context: str,
    user_text: str,
    now: datetime | None = None,
) -> str:
    current_time = now or utcnow()
    memories = list(
        await session.scalars(
            select(MemoryItem)
            .where(
                MemoryItem.account_id == account_id,
                MemoryItem.deleted_at.is_(None),
                or_(
                    MemoryItem.expires_at.is_(None),
                    MemoryItem.expires_at > current_time,
                ),
            )
            .order_by(MemoryItem.last_seen_at.desc())
            .limit(MAX_CANDIDATE_ROWS)
        )
    )
    if not memories:
        return ""

    ranked = rank_memories(
        memories,
        focus_context=focus_context,
        user_text=user_text,
        now=current_time,
    )[:MAX_MEMORY_RESULTS]
    for memory in ranked:
        memory.last_used_at = current_time

    lines = [f"- {memory.kind}: {memory.text}" for memory in ranked]
    context = "\n".join(lines)
    return context[:MAX_MEMORY_CONTEXT_CHARS]
