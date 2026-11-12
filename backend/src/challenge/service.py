from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from challenge.schemas import (
    ChallengeCreate,
    ChallengeItemOut,
    ChallengeListOut,
    ChallengeOut,
)
from clock import utcnow
from errors import ApiError
from models import Challenge, ChallengeItem, Discovery, Word


async def _get_challenge(
    session: AsyncSession,
    account_id: str,
    challenge_id: str,
) -> Challenge:
    challenge = await session.scalar(
        select(Challenge).where(
            Challenge.id == challenge_id,
            Challenge.account_id == account_id,
        )
    )
    if challenge is None:
        raise ApiError("Challenge not found.", status_code=404, code="challenge_not_found")
    return challenge


async def _challenge_out(
    session: AsyncSession,
    challenge: Challenge,
) -> ChallengeOut:
    items = list(
        await session.scalars(
            select(ChallengeItem)
            .where(ChallengeItem.challenge_id == challenge.id)
            .order_by(ChallengeItem.position)
        )
    )
    discovery_ids = [item.discovery_id for item in items]
    discoveries = {
        row.id: row
        for row in await session.scalars(
            select(Discovery).where(
                Discovery.id.in_(discovery_ids),
                Discovery.account_id == challenge.account_id,
                Discovery.deleted_at.is_(None),
            )
        )
    }
    word_ids = {
        row.word_id for row in discoveries.values() if row.focus_kind == "word" and row.word_id
    }
    words = (
        {row.id: row for row in await session.scalars(select(Word).where(Word.id.in_(word_ids)))}
        if word_ids
        else {}
    )

    out_items: list[ChallengeItemOut] = []
    for item in items:
        discovery = discoveries.get(item.discovery_id)
        if discovery is None:
            continue
        if discovery.focus_kind == "word" and discovery.word_id:
            word = words.get(discovery.word_id)
            title = word.label_en if word is not None else "Word"
            subtitle = discovery.input_text
            focus_type = "word"
            focus_id = discovery.word_id
        else:
            title = "Moment"
            if discovery.scene_payload_json:
                natural = discovery.scene_payload_json.get("natural_english")
                if isinstance(natural, str) and natural.strip():
                    title = natural.strip()
            subtitle = discovery.input_text
            focus_type = "scene"
            focus_id = discovery.id
        out_items.append(
            ChallengeItemOut(
                id=item.id,
                discovery_id=item.discovery_id,
                position=item.position,
                visited_at=item.visited_at,
                focus_type=focus_type,
                focus_id=focus_id,
                title=title,
                subtitle=subtitle,
            )
        )

    due_at = challenge.started_at + timedelta(days=challenge.planned_days)
    return ChallengeOut(
        id=challenge.id,
        name=challenge.name,
        planned_days=challenge.planned_days,
        status=challenge.status,
        started_at=challenge.started_at,
        ended_at=challenge.ended_at,
        created_at=challenge.created_at,
        total_count=len(out_items),
        visited_count=sum(1 for item in out_items if item.visited_at is not None),
        is_due=challenge.status == "active" and utcnow() >= due_at,
        items=out_items,
    )


async def list_challenges(
    session: AsyncSession,
    account_id: str,
) -> ChallengeListOut:
    challenges = list(
        await session.scalars(
            select(Challenge)
            .where(Challenge.account_id == account_id)
            .order_by(Challenge.created_at.desc())
        )
    )
    return ChallengeListOut(
        items=[await _challenge_out(session, challenge) for challenge in challenges]
    )


async def create_challenge(
    session: AsyncSession,
    account_id: str,
    payload: ChallengeCreate,
) -> ChallengeOut:
    active = await session.scalar(
        select(Challenge).where(
            Challenge.account_id == account_id,
            Challenge.status == "active",
        )
    )
    if active is not None:
        raise ApiError(
            "Finish the active challenge first.",
            status_code=409,
            code="active_challenge_exists",
        )

    discovery_ids = list(dict.fromkeys(payload.discovery_ids))
    discoveries = list(
        await session.scalars(
            select(Discovery).where(
                Discovery.id.in_(discovery_ids),
                Discovery.account_id == account_id,
                Discovery.deleted_at.is_(None),
                Discovery.status == "ready",
                Discovery.focus_kind.in_(("word", "scene")),
            )
        )
    )
    if len(discoveries) != len(discovery_ids):
        raise ApiError(
            "Choose valid Word or Moment discoveries.",
            status_code=400,
            code="invalid_challenge_content",
        )

    challenge = Challenge(
        account_id=account_id,
        name=" ".join(payload.name.split()),
        planned_days=payload.planned_days,
        status="active",
    )
    session.add(challenge)
    await session.flush()
    for index, discovery_id in enumerate(discovery_ids):
        session.add(
            ChallengeItem(
                challenge_id=challenge.id,
                discovery_id=discovery_id,
                position=index,
            )
        )
    await session.commit()
    await session.refresh(challenge)
    return await _challenge_out(session, challenge)


async def get_challenge(
    session: AsyncSession,
    account_id: str,
    challenge_id: str,
) -> ChallengeOut:
    challenge = await _get_challenge(session, account_id, challenge_id)
    return await _challenge_out(session, challenge)


async def mark_visited(
    session: AsyncSession,
    account_id: str,
    challenge_id: str,
    item_id: str,
) -> ChallengeOut:
    challenge = await _get_challenge(session, account_id, challenge_id)
    item = await session.scalar(
        select(ChallengeItem).where(
            ChallengeItem.id == item_id,
            ChallengeItem.challenge_id == challenge.id,
        )
    )
    if item is None:
        raise ApiError(
            "Challenge item not found.", status_code=404, code="challenge_item_not_found"
        )
    if item.visited_at is None:
        item.visited_at = utcnow()
        await session.commit()
        await session.refresh(challenge)
    return await _challenge_out(session, challenge)


async def end_challenge(
    session: AsyncSession,
    account_id: str,
    challenge_id: str,
) -> ChallengeOut:
    challenge = await _get_challenge(session, account_id, challenge_id)
    if challenge.status == "active":
        challenge.status = "ended"
        challenge.ended_at = utcnow()
        await session.commit()
        await session.refresh(challenge)
    return await _challenge_out(session, challenge)
