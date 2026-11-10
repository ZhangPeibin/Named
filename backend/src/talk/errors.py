from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from models import ErrorPattern
from talk.schemas import Correction

ERROR_PATTERNS: dict[str, dict[str, str]] = {
    "grammar": {
        "third_person_s": "third-person singular -s",
        "articles": "articles a / an / the",
        "prepositions": "prepositions",
        "verb_tense": "verb tense",
        "verb_form": "verb form",
        "subject_verb_agreement": "subject-verb agreement",
        "plural": "plural nouns",
        "word_order": "word order",
        "pronouns": "pronouns",
        "comparatives": "comparatives",
        "modal_verbs": "modal verbs",
        "other_grammar": "other grammar",
    },
    "vocabulary": {
        "word_choice": "word choice",
        "collocation": "word collocation",
        "word_form": "word form",
        "other_vocabulary": "other vocabulary",
    },
    "spelling": {
        "spelling": "spelling",
    },
    "naturalness": {
        "awkward_phrasing": "awkward phrasing",
        "redundancy": "redundancy",
        "register": "register / tone",
        "other_naturalness": "other naturalness",
    },
}
DEFAULT_PATTERNS = {
    "grammar": "other_grammar",
    "vocabulary": "other_vocabulary",
    "spelling": "spelling",
    "naturalness": "other_naturalness",
}
MAX_ERROR_RESULTS = 5
ERROR_LOOKBACK_DAYS = 90


def normalize_error(
    category: str | None,
    pattern: str | None,
) -> tuple[str, str]:
    normalized_category = (category or "").strip().lower()
    normalized_pattern = (pattern or "").strip().lower()

    if normalized_pattern:
        for candidate_category, patterns in ERROR_PATTERNS.items():
            if normalized_pattern in patterns:
                if normalized_category not in ERROR_PATTERNS:
                    normalized_category = candidate_category
                if normalized_category != candidate_category:
                    normalized_category = candidate_category
                return normalized_category, normalized_pattern

    if normalized_category not in ERROR_PATTERNS:
        normalized_category = "grammar"
    return normalized_category, DEFAULT_PATTERNS[normalized_category]


def pattern_label(category: str, pattern_key: str) -> str:
    return ERROR_PATTERNS.get(category, {}).get(pattern_key, pattern_key)


async def record_error_profile(
    session: AsyncSession,
    account_id: str,
    corrections: list[Correction],
    *,
    now: datetime | None = None,
) -> list[ErrorPattern]:
    current_time = now or utcnow()
    recorded: list[ErrorPattern] = []
    for correction in corrections:
        category, pattern_key = normalize_error(correction.category, correction.pattern)
        row = await session.scalar(
            select(ErrorPattern).where(
                ErrorPattern.account_id == account_id,
                ErrorPattern.category == category,
                ErrorPattern.pattern_key == pattern_key,
            )
        )
        if row is None:
            row = ErrorPattern(
                account_id=account_id,
                category=category,
                pattern_key=pattern_key,
                label=pattern_label(category, pattern_key),
                occurrence_count=1,
                first_seen_at=current_time,
                last_seen_at=current_time,
                example_original=correction.original,
                example_suggestion=correction.suggestion,
            )
            session.add(row)
        else:
            row.occurrence_count += 1
            row.last_seen_at = current_time
            row.label = pattern_label(category, pattern_key)
            row.example_original = correction.original
            row.example_suggestion = correction.suggestion
        recorded.append(row)

    if recorded:
        await session.flush()
    return recorded


async def get_error_profile_context(
    session: AsyncSession,
    account_id: str,
    *,
    limit: int = MAX_ERROR_RESULTS,
    now: datetime | None = None,
) -> str:
    current_time = now or utcnow()
    cutoff = current_time - timedelta(days=ERROR_LOOKBACK_DAYS)
    rows = list(
        await session.scalars(
            select(ErrorPattern)
            .where(
                ErrorPattern.account_id == account_id,
                ErrorPattern.last_seen_at >= cutoff,
            )
            .order_by(
                ErrorPattern.occurrence_count.desc(),
                ErrorPattern.last_seen_at.desc(),
            )
            .limit(limit)
        )
    )
    if not rows:
        return ""

    lines: list[str] = []
    for row in rows:
        days = max(0, (current_time - row.last_seen_at).days)
        last_seen = "today" if days == 0 else f"{days} day(s) ago"
        example = ""
        if row.example_original and row.example_suggestion:
            example = f'; example: "{row.example_original}" -> "{row.example_suggestion}"'
        lines.append(
            f"- {row.category} / {row.label}: {row.occurrence_count} time(s), "
            f"last seen {last_seen}{example}"
        )
    return "\n".join(lines)
