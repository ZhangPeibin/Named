import math
import re
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from config import Settings
from models import Experience, ExperienceSource

MAX_EXPERIENCE_RESULTS = 3
MAX_EXPERIENCE_CONTEXT_CHARS = 1200
MAX_CANDIDATE_ROWS = 200
KIND_WEIGHTS = {"life": 1.0, "learning": 0.9}
HALF_LIFE_DAYS = {"life": 365.0, "learning": 90.0}


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


def _score(
    experience: Experience,
    *,
    query_tokens: set[str],
    source_text: str,
    now: datetime,
) -> float:
    experience_tokens = _tokens(f"{experience.summary} {experience.detail or ''} {source_text}")
    overlap = len(experience_tokens & query_tokens)
    if overlap == 0:
        return 0.0
    relevance = min(1.0, overlap / max(1, min(len(experience_tokens), 8)))
    age_days = max(0.0, (now - experience.created_at).total_seconds() / 86400)
    half_life = HALF_LIFE_DAYS.get(experience.kind, 180.0)
    recency = math.exp(-math.log(2) * age_days / half_life)
    kind_weight = KIND_WEIGHTS.get(experience.kind, 0.5)
    return relevance * recency * kind_weight * max(0.0, min(1.0, experience.confidence))


async def get_experience_context(
    session: AsyncSession,
    account_id: str,
    *,
    focus_context: str,
    user_text: str,
    settings: Settings,
    now: datetime | None = None,
) -> str:
    current_time = now or utcnow()
    query_tokens = _tokens(f"{focus_context} {user_text}")
    if not query_tokens:
        return ""

    experiences = list(
        await session.scalars(
            select(Experience)
            .where(
                Experience.account_id == account_id,
                Experience.deleted_at.is_(None),
                Experience.confidence >= settings.experience_confidence_threshold,
            )
            .order_by(Experience.created_at.desc())
            .limit(MAX_CANDIDATE_ROWS)
        )
    )
    source_text_by_experience: dict[str, list[str]] = {}
    if experiences:
        experience_ids = [experience.id for experience in experiences]
        for source in await session.scalars(
            select(ExperienceSource).where(
                ExperienceSource.experience_id.in_(experience_ids),
                ExperienceSource.source_type.in_(("expression", "message")),
            )
        ):
            source_text_by_experience.setdefault(source.experience_id, []).append(
                source.quote or source.source_id
            )

    ranked = sorted(
        (
            experience
            for experience in experiences
            if _score(
                experience,
                query_tokens=query_tokens,
                source_text=" ".join(source_text_by_experience.get(experience.id, [])),
                now=current_time,
            )
            > 0
        ),
        key=lambda experience: _score(
            experience,
            query_tokens=query_tokens,
            source_text=" ".join(source_text_by_experience.get(experience.id, [])),
            now=current_time,
        ),
        reverse=True,
    )[:MAX_EXPERIENCE_RESULTS]
    if not ranked:
        return ""

    lines = [f"- {experience.kind}: {experience.summary}" for experience in ranked]
    return "\n".join(lines)[:MAX_EXPERIENCE_CONTEXT_CHARS]
