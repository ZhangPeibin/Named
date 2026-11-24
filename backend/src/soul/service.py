from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from errors import ApiError
from memory.service import memory_key
from models import MemoryItem, SoulProfile
from soul.schemas import InitialSoul, SoulItemCreate, SoulItemUpdate, SoulUpdate


async def get_profile(session: AsyncSession, account_id: str) -> SoulProfile:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        raise ApiError("Soul not found.", status_code=404, code="soul_not_found")
    return profile


async def get_soul(
    session: AsyncSession,
    account_id: str,
) -> tuple[SoulProfile, list[MemoryItem]]:
    profile = await get_profile(session, account_id)
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
    return profile, list(items)


async def bind_initial_soul(
    session: AsyncSession,
    account_id: str,
    initial_soul: InitialSoul,
) -> SoulProfile:
    existing = await session.get(SoulProfile, account_id)
    if existing is not None:
        return existing

    profile = SoulProfile(
        account_id=account_id,
        native_language=initial_soul.native_language,
        age=initial_soul.age,
        gender=initial_soul.gender,
    )
    session.add(profile)
    for raw_interest in initial_soul.interests:
        interest = raw_interest.strip()
        if interest:
            session.add(
                MemoryItem(
                    account_id=account_id,
                    scope="about",
                    kind="interest",
                    text=interest,
                    canonical_key=memory_key("interest", interest),
                    source_type="onboarding",
                    source_id="onboarding",
                    confidence=0.9,
                    importance=0.6,
                    mention_count=1,
                    status="active",
                    valid_from=utcnow(),
                )
            )
    await session.flush()
    return profile


async def update_soul(
    session: AsyncSession,
    account_id: str,
    payload: SoulUpdate,
) -> tuple[SoulProfile, list[MemoryItem]]:
    profile = await get_profile(session, account_id)
    fields = payload.model_fields_set

    if "native_language" in fields:
        if payload.native_language is None:
            raise ApiError(
                "native_language is required.",
                code="native_language_required",
            )
        profile.native_language = payload.native_language
    if "age" in fields:
        profile.age = payload.age
    if "gender" in fields:
        profile.gender = payload.gender
    if "auto_extract" in fields and payload.auto_extract is not None:
        profile.auto_extract = payload.auto_extract

    profile.updated_at = utcnow()
    await session.commit()
    return await get_soul(session, account_id)


async def create_item(
    session: AsyncSession,
    account_id: str,
    payload: SoulItemCreate,
) -> MemoryItem:
    await get_profile(session, account_id)
    item = MemoryItem(
        account_id=account_id,
        scope="about",
        kind=payload.kind,
        text=payload.text,
        canonical_key=memory_key(payload.kind, payload.text),
        source_type="user_edit",
        source_id="user_edit",
        confidence=0.9,
        importance=0.6,
        mention_count=1,
        status="active",
        valid_from=utcnow(),
    )
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item


async def _get_item(session: AsyncSession, account_id: str, item_id: str) -> MemoryItem:
    item = await session.scalar(
        select(MemoryItem).where(
            MemoryItem.id == item_id,
            MemoryItem.account_id == account_id,
            MemoryItem.scope == "about",
            MemoryItem.deleted_at.is_(None),
        )
    )
    if item is None:
        raise ApiError("Soul item not found.", status_code=404, code="soul_item_not_found")
    return item


async def update_item(
    session: AsyncSession,
    account_id: str,
    item_id: str,
    payload: SoulItemUpdate,
) -> MemoryItem:
    item = await _get_item(session, account_id, item_id)
    fields = payload.model_fields_set

    if "kind" in fields:
        if payload.kind is None:
            raise ApiError("kind is required.", code="kind_required")
        item.kind = payload.kind
    if "text" in fields:
        if payload.text is None:
            raise ApiError("text is required.", code="text_required")
        item.text = payload.text

    item.canonical_key = memory_key(item.kind, item.text)
    item.updated_at = utcnow()
    await session.commit()
    await session.refresh(item)
    return item


async def delete_item(session: AsyncSession, account_id: str, item_id: str) -> None:
    item = await _get_item(session, account_id, item_id)
    item.deleted_at = utcnow()
    await session.commit()
