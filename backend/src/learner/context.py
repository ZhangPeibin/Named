from __future__ import annotations

import re
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from config import Settings
from experience.context import get_experience_context
from memory.service import get_boundary_terms, get_memory_context, get_word_memory_context
from models import MemoryItem, SoulProfile
from talk.errors import get_error_profile_context

MAX_LEARNER_CONTEXT_CHARS = 1800

_ABOUT_HEADER = "About the learner:"
_WORDS_HEADER = "Word encounters:"
_LEARNED_HEADER = "Learned patterns and memories:"
_ERRORS_HEADER = "Recurring errors:"
_EXPERIENCES_HEADER = "Relevant experiences:"

_LEADING_BULLET = re.compile(r"^-\s*")
_SOURCE_SUFFIX = re.compile(r"\s*\(source: [^)]*\)\s*$")
_TRAILING_DETAIL = re.compile(r"\s*\([^)]*\)\s*$")
_KIND_PREFIX = re.compile(r"^[a-z_]+:\s*")


def _line_key(line: str) -> str:
    text = _LEADING_BULLET.sub("", line.strip())
    text = _SOURCE_SUFFIX.sub("", text)
    text = _TRAILING_DETAIL.sub("", text)
    text = _KIND_PREFIX.sub("", text)
    return " ".join(text.lower().split())


def _split_lines(block: str) -> list[str]:
    return [line.strip() for line in block.splitlines() if line.strip()]


def _apply_boundaries(lines: list[str], boundaries: list[str]) -> list[str]:
    if not boundaries:
        return lines
    return [
        line
        for line in lines
        if not any(term in " ".join(line.lower().split()) for term in boundaries)
    ]


def _dedupe_lines(lines: list[str], seen: set[str]) -> list[str]:
    deduped: list[str] = []
    for line in lines:
        key = _line_key(line)
        if not key or key in seen:
            continue
        seen.add(key)
        deduped.append(line)
    return deduped


def _fit_lines(lines: list[str], budget: int) -> list[str]:
    fitted: list[str] = []
    used = 0
    for line in lines:
        cost = len(line) + 1
        if used + cost <= budget:
            fitted.append(line)
            used += cost
            continue
        remaining = budget - used - 1
        if remaining > 0:
            fitted.append(line[:remaining])
        break
    return fitted


def _render_sections(sections: list[tuple[str, list[str]]], budget: int) -> str:
    rendered: list[str] = []
    used = 0
    for header, lines in sections:
        if not lines:
            continue
        header_cost = len(header) + 1
        if used + header_cost > budget:
            break
        body = _fit_lines(lines, budget - used - header_cost)
        if not body:
            continue
        rendered.append(header)
        rendered.extend(body)
        used += header_cost + sum(len(line) + 1 for line in body)
    return "\n".join(rendered)


async def _about_lines(session: AsyncSession, account_id: str) -> list[str]:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        return []
    lines = [f"- profile: native language {profile.native_language}"]
    if profile.age is not None:
        lines.append(f"- profile: age {profile.age} (learner-provided; do not infer)")
    if profile.gender is not None:
        lines.append(f"- profile: gender {profile.gender} (learner-provided; do not infer)")
    items = await session.scalars(
        select(MemoryItem)
        .where(
            MemoryItem.account_id == account_id,
            MemoryItem.scope == "about",
            MemoryItem.status == "active",
            MemoryItem.deleted_at.is_(None),
        )
        .order_by(MemoryItem.created_at)
    )
    for item in items:
        lines.append(f"- {item.kind}: {item.text} (source: {item.source})")
    return lines


async def build_learner_context(
    session: AsyncSession,
    account_id: str,
    *,
    focus_context: str,
    user_text: str,
    settings: Settings,
    use_memory: bool = True,
    now: datetime | None = None,
) -> str:
    current_time = now or utcnow()
    seen: set[str] = set()
    sections: list[tuple[str, list[str]]] = []
    boundaries = await get_boundary_terms(session, account_id)

    about = await _about_lines(session, account_id) if use_memory else []
    about = _apply_boundaries(about, boundaries)
    sections.append((_ABOUT_HEADER, _dedupe_lines(about, seen)))

    words = _split_lines(await get_word_memory_context(session, account_id, now=current_time))
    words = _apply_boundaries(words, boundaries)
    sections.append((_WORDS_HEADER, _dedupe_lines(words, seen)))

    learned = _split_lines(
        await get_memory_context(
            session,
            account_id,
            focus_context=focus_context,
            user_text=user_text,
            now=current_time,
        )
    )
    learned = _apply_boundaries(learned, boundaries)
    sections.append((_LEARNED_HEADER, _dedupe_lines(learned, seen)))

    errors = _split_lines(await get_error_profile_context(session, account_id, now=current_time))
    errors = _apply_boundaries(errors, boundaries)
    sections.append((_ERRORS_HEADER, _dedupe_lines(errors, seen)))

    try:
        experiences = _split_lines(
            await get_experience_context(
                session,
                account_id,
                focus_context=focus_context,
                user_text=user_text,
                settings=settings,
                now=current_time,
            )
        )
    except Exception:
        experiences = []
    experiences = _apply_boundaries(experiences, boundaries)
    sections.append((_EXPERIENCES_HEADER, _dedupe_lines(experiences, seen)))

    return _render_sections(sections, MAX_LEARNER_CONTEXT_CHARS)
