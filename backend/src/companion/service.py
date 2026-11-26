import secrets

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from companion.moderation import hobby_is_allowed, name_is_allowed
from companion.schemas import CompanionOut, CompanionUpdate
from errors import ApiError
from models import CompanionProfile

RANDOM_NAMES = (
    "Momo",
    "Miso",
    "Tofu",
    "Bao",
    "Bean",
    "Mochi",
    "Yuzu",
    "Sesame",
    "Moss",
    "Clover",
    "Pebble",
    "Sprout",
    "Poppy",
    "Sora",
    "Pip",
    "Nori",
    "Kiki",
    "Lulu",
    "Pepper",
    "Button",
)

MAX_NAME_LENGTH = 16
MAX_HOBBY_LENGTH = 24


def _clean(value: str) -> str:
    return " ".join(value.split())


def _validate_name(value: str) -> str:
    name = _clean(value)
    if not name:
        raise ApiError(
            "A companion name is required.",
            code="companion_name_required",
        )
    if len(name) > MAX_NAME_LENGTH:
        raise ApiError(
            "That companion name is too long.",
            code="companion_name_too_long",
        )
    if not name_is_allowed(name):
        raise ApiError(
            "That companion name is not allowed.",
            code="companion_name_rejected",
        )
    return name


def _validate_hobby(value: str | None) -> str | None:
    if value is None:
        return None
    hobby = _clean(value)
    if not hobby:
        return None
    if len(hobby) > MAX_HOBBY_LENGTH:
        raise ApiError(
            "That companion hobby is too long.",
            code="companion_hobby_too_long",
        )
    if not hobby_is_allowed(hobby):
        raise ApiError(
            "That companion hobby is not allowed.",
            code="companion_hobby_rejected",
        )
    return hobby


def _to_out(profile: CompanionProfile) -> CompanionOut:
    return CompanionOut(
        name=profile.name,
        gender=profile.gender,
        hobby=profile.hobby,
        avatar_key=profile.avatar_key,
        voice_key=profile.voice_key,
        setup_dismissed=profile.setup_dismissed_at is not None,
        updated_at=profile.updated_at,
    )


async def get_companion(session: AsyncSession, account_id: str) -> CompanionProfile:
    profile = await session.get(CompanionProfile, account_id)
    if profile is not None:
        return profile
    profile = CompanionProfile(account_id=account_id)
    session.add(profile)
    try:
        await session.commit()
    except IntegrityError:
        await session.rollback()
        existing = await session.get(CompanionProfile, account_id)
        if existing is None:
            raise
        return existing
    await session.refresh(profile)
    return profile


async def get_companion_out(session: AsyncSession, account_id: str) -> CompanionOut:
    return _to_out(await get_companion(session, account_id))


def _random_name(exclude: str | None = None) -> str:
    choices = [name for name in RANDOM_NAMES if name != exclude]
    return secrets.choice(choices or list(RANDOM_NAMES))


async def suggest_name(session: AsyncSession, account_id: str) -> str:
    profile = await get_companion(session, account_id)
    return _random_name(profile.name)


async def update_companion(
    session: AsyncSession,
    account_id: str,
    payload: CompanionUpdate,
) -> CompanionOut:
    profile = await get_companion(session, account_id)
    fields = payload.model_fields_set
    if "name" in fields:
        if payload.name is None:
            raise ApiError(
                "A companion name is required.",
                code="companion_name_required",
            )
        was_named = bool(profile.name and profile.name.strip())
        profile.name = _validate_name(payload.name)
        if not was_named and profile.named_at is None:
            profile.named_at = utcnow()
    if "gender" in fields:
        profile.gender = payload.gender
    if "hobby" in fields:
        profile.hobby = _validate_hobby(payload.hobby)
    if "setup_dismissed" in fields and payload.setup_dismissed is not None:
        profile.setup_dismissed_at = utcnow() if payload.setup_dismissed else None
    profile.updated_at = utcnow()
    await session.commit()
    await session.refresh(profile)
    return _to_out(profile)


async def assign_random_name(session: AsyncSession, account_id: str) -> CompanionOut:
    profile = await get_companion(session, account_id)
    profile.name = _random_name(profile.name)
    if profile.named_at is None:
        profile.named_at = utcnow()
    profile.updated_at = utcnow()
    await session.commit()
    await session.refresh(profile)
    return _to_out(profile)


async def rename_companion(
    session: AsyncSession,
    account_id: str,
    name: str,
) -> CompanionOut:
    return await update_companion(
        session,
        account_id,
        CompanionUpdate(name=name),
    )
