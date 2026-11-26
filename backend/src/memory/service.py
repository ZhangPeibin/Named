from __future__ import annotations

import hashlib
import math
import re
from datetime import datetime

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from models import Discovery, MemoryItem, Word, WordProgress
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

BOUNDARY_KINDS = frozenset({"do_not_mention", "do_not_remember"})
ABOUT_KINDS = frozenset({"identity", "preference"})
AI_SOURCE_TYPES = frozenset({"ai_inference", "agent_inference"})
NEGATION_MARKERS = ("not", "n't", "never", "no longer", "不再", "不", "没", "讨厌")
MIN_SUPERSEDE_CONFIDENCE = 0.9


def _scope_for_kind(kind: str) -> str:
    if kind in BOUNDARY_KINDS:
        return "boundary"
    if kind in ABOUT_KINDS:
        return "about"
    return "learned"


def _canonical_key(kind: str, text: str) -> str:
    normalized = " ".join(text.strip().lower().split())
    return hashlib.sha256(f"{kind}:{normalized}".encode()).hexdigest()


def memory_key(kind: str, text: str) -> str:
    return _canonical_key(kind, text)


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


def _has_negation(text: str) -> bool:
    lowered = text.lower()
    return any(marker in lowered for marker in NEGATION_MARKERS)


def _is_ai_source(source_type: str) -> bool:
    return source_type in AI_SOURCE_TYPES


def _shares_tokens(left: str, right: str, minimum: int = 2) -> bool:
    return len(_tokens(left) & _tokens(right)) >= minimum


def _normalized(text: str) -> str:
    return " ".join(text.lower().split())


def _matches_replacement(
    row: MemoryItem,
    candidate: MemoryCandidate,
    text: str,
) -> bool:
    if candidate.replaces_text:
        replaced = _normalized(candidate.replaces_text)
        if replaced and (replaced in _normalized(row.text) or _normalized(row.text) in replaced):
            return True
    return _shares_tokens(text, row.text)


def _can_supersede(row: MemoryItem, candidate: MemoryCandidate, source_type: str) -> bool:
    if _is_ai_source(row.source_type) and not _is_ai_source(source_type):
        return True
    if _is_ai_source(row.source_type) and _is_ai_source(source_type):
        return candidate.confidence >= MIN_SUPERSEDE_CONFIDENCE
    return True


def _new_memory(
    *,
    account_id: str,
    candidate: MemoryCandidate,
    text: str,
    key: str,
    source_type: str,
    source_id: str,
    current_time: datetime,
    status: str = "active",
) -> MemoryItem:
    scope = _scope_for_kind(candidate.kind)
    return MemoryItem(
        account_id=account_id,
        scope=scope,
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
        status=status,
        valid_from=current_time if status == "active" else None,
    )


def _merge_memory(
    row: MemoryItem,
    candidate: MemoryCandidate,
    text: str,
    *,
    source_type: str,
    source_id: str,
    current_time: datetime,
) -> None:
    row.text = text
    row.source_type = source_type
    row.source_id = source_id
    row.confidence = max(row.confidence, candidate.confidence)
    row.importance = max(row.importance, candidate.importance)
    row.mention_count += 1
    row.last_seen_at = current_time
    row.expires_at = None
    if _scope_for_kind(candidate.kind) == "about" and row.scope == "learned":
        row.scope = "about"
    if row.status != "active":
        row.status = "active"
        row.valid_from = current_time


async def _active_row(
    session: AsyncSession,
    account_id: str,
    kind: str,
    key: str,
) -> MemoryItem | None:
    return await session.scalar(
        select(MemoryItem).where(
            MemoryItem.account_id == account_id,
            MemoryItem.kind == kind,
            MemoryItem.canonical_key == key,
            MemoryItem.status == "active",
            MemoryItem.deleted_at.is_(None),
        )
    )


async def _active_rows_for_kind(
    session: AsyncSession,
    account_id: str,
    kind: str,
) -> list[MemoryItem]:
    return list(
        await session.scalars(
            select(MemoryItem)
            .where(
                MemoryItem.account_id == account_id,
                MemoryItem.kind == kind,
                MemoryItem.status == "active",
                MemoryItem.deleted_at.is_(None),
            )
            .order_by(MemoryItem.last_seen_at.desc())
            .limit(MAX_CANDIDATE_ROWS)
        )
    )


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
    prepared: list[tuple[MemoryCandidate, str, str]] = []
    keys: set[str] = set()
    for candidate in candidates:
        text = _clean_text(candidate.text)
        if not text:
            continue
        key = _canonical_key(candidate.kind, text)
        if key in keys:
            continue
        prepared.append((candidate, text, key))
        keys.add(key)

    if not prepared:
        return []

    recorded: list[MemoryItem] = []
    for candidate, text, key in prepared:
        if candidate.kind in BOUNDARY_KINDS:
            row = await _active_row(session, account_id, candidate.kind, key)
            if row is not None:
                _merge_memory(
                    row,
                    candidate,
                    text,
                    source_type=source_type,
                    source_id=source_id,
                    current_time=current_time,
                )
                recorded.append(row)
                continue
            row = _new_memory(
                account_id=account_id,
                candidate=candidate,
                text=text,
                key=key,
                source_type=source_type,
                source_id=source_id,
                current_time=current_time,
            )
            session.add(row)
            recorded.append(row)
            continue

        if candidate.relation == "contradicts":
            row = _new_memory(
                account_id=account_id,
                candidate=candidate,
                text=text,
                key=key,
                source_type=source_type,
                source_id=source_id,
                current_time=current_time,
                status="conflicted",
            )
            session.add(row)
            recorded.append(row)
            continue

        existing = await _active_row(session, account_id, candidate.kind, key)
        if existing is not None:
            _merge_memory(
                existing,
                candidate,
                text,
                source_type=source_type,
                source_id=source_id,
                current_time=current_time,
            )
            recorded.append(existing)
            continue

        if candidate.relation == "replaces" or _has_negation(text):
            targets = [
                row
                for row in await _active_rows_for_kind(session, account_id, candidate.kind)
                if _matches_replacement(row, candidate, text)
            ]
            if targets:
                supersedable = [
                    row for row in targets if _can_supersede(row, candidate, source_type)
                ]
                status = "active" if supersedable else "conflicted"
                row = _new_memory(
                    account_id=account_id,
                    candidate=candidate,
                    text=text,
                    key=key,
                    source_type=source_type,
                    source_id=source_id,
                    current_time=current_time,
                    status=status,
                )
                session.add(row)
                if status == "active":
                    await session.flush()
                    for old in supersedable:
                        old.status = "superseded"
                        old.superseded_by = row.id
                        old.valid_until = current_time
                recorded.append(row)
                continue

        row = _new_memory(
            account_id=account_id,
            candidate=candidate,
            text=text,
            key=key,
            source_type=source_type,
            source_id=source_id,
            current_time=current_time,
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
                MemoryItem.status == "active",
                MemoryItem.scope == "learned",
                MemoryItem.kind.not_in(BOUNDARY_KINDS),
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


async def get_boundary_terms(session: AsyncSession, account_id: str) -> list[str]:
    rows = await session.scalars(
        select(MemoryItem.text).where(
            MemoryItem.account_id == account_id,
            MemoryItem.scope == "boundary",
            MemoryItem.kind.in_(BOUNDARY_KINDS),
            MemoryItem.status == "active",
            MemoryItem.deleted_at.is_(None),
        )
    )
    return [term for term in (_normalized(text) for text in rows) if term]


async def get_word_memory_context(
    session: AsyncSession,
    account_id: str,
    *,
    limit: int = 5,
    now: datetime | None = None,
) -> str:
    current_time = now or utcnow()
    rows = list(
        await session.execute(
            select(
                Discovery.word_id,
                func.count(Discovery.id),
                func.max(Discovery.created_at),
            )
            .where(
                Discovery.account_id == account_id,
                Discovery.word_id.is_not(None),
                Discovery.deleted_at.is_(None),
            )
            .group_by(Discovery.word_id)
            .order_by(func.max(Discovery.created_at).desc())
            .limit(limit)
        )
    )
    word_ids = [row[0] for row in rows]
    if not word_ids:
        return ""
    labels = {
        word.id: word.label_en
        for word in await session.scalars(select(Word).where(Word.id.in_(word_ids)))
    }
    progress = {
        row.word_id: row
        for row in await session.scalars(
            select(WordProgress).where(
                WordProgress.account_id == account_id,
                WordProgress.word_id.in_(word_ids),
            )
        )
    }
    word_memory_counts = {
        _normalized(row.text): row.mention_count
        for row in await session.scalars(
            select(MemoryItem).where(
                MemoryItem.account_id == account_id,
                MemoryItem.scope == "learned",
                MemoryItem.kind == "word",
                MemoryItem.status == "active",
                MemoryItem.deleted_at.is_(None),
            )
        )
    }
    lines: list[str] = []
    for word_id, seen, last_seen in rows:
        label = labels.get(word_id)
        if not label:
            continue
        row = progress.get(word_id)
        used = row.used_count if row is not None else 0
        practiced = row.practice_count if row is not None else 0
        seen = max(seen, word_memory_counts.get(_normalized(label), 0))
        age_days = max(0, (current_time - last_seen).days)
        lines.append(
            f"- word: {label} (seen {seen} time(s), used {used} time(s), "
            f"practiced {practiced} time(s); last seen {age_days} day(s) ago)"
        )
    return "\n".join(lines)
