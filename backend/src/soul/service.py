from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from errors import ApiError
from models import SoulItem, SoulProfile
from soul.schemas import InitialSoul, SoulItemCreate, SoulItemUpdate, SoulUpdate


async def get_profile(session: AsyncSession, account_id: str) -> SoulProfile:
    profile = await session.get(SoulProfile, account_id)
    if profile is None:
        raise ApiError("Soul not found.", status_code=404, code="soul_not_found")
    return profile


async def get_soul(session: AsyncSession, account_id: str) -> tuple[SoulProfile, list[SoulItem]]:
    profile = await get_profile(session, account_id)
    items = await session.scalars(
        select(SoulItem)
        .where(SoulItem.account_id == account_id, SoulItem.deleted_at.is_(None))
        .order_by(SoulItem.created_at)
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
                SoulItem(
                    account_id=account_id,
                    kind="interest",
                    text=interest,
                    source="onboarding",
                )
            )
    await session.flush()
    return profile


async def update_soul(
    session: AsyncSession,
    account_id: str,
    payload: SoulUpdate,
) -> tuple[SoulProfile, list[SoulItem]]:
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

    profile.updated_at = utcnow()
    await session.commit()
    return await get_soul(session, account_id)


async def create_item(
    session: AsyncSession,
    account_id: str,
    payload: SoulItemCreate,
) -> SoulItem:
    await get_profile(session, account_id)
    item = SoulItem(
        account_id=account_id,
        kind=payload.kind,
        text=payload.text,
        source="user_edit",
    )
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item


async def _get_item(session: AsyncSession, account_id: str, item_id: str) -> SoulItem:
    item = await session.scalar(
        select(SoulItem).where(
            SoulItem.id == item_id,
            SoulItem.account_id == account_id,
            SoulItem.deleted_at.is_(None),
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
) -> SoulItem:
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

    item.updated_at = utcnow()
    await session.commit()
    await session.refresh(item)
    return item


async def delete_item(session: AsyncSession, account_id: str, item_id: str) -> None:
    item = await _get_item(session, account_id, item_id)
    item.deleted_at = utcnow()
    await session.commit()
