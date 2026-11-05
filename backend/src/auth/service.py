import hashlib
import hmac
import secrets
from datetime import datetime, timedelta

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from clock import utcnow
from config import Settings
from errors import ApiError as AuthError
from mailer import EmailSender
from models import Account, AuthCode, AuthSession, SoulProfile
from soul.schemas import InitialSoul
from soul.service import bind_initial_soul


class RateLimited(AuthError):
    def __init__(self, retry_after: int) -> None:
        super().__init__(
            "Too many requests. Try again later.",
            status_code=429,
            code="rate_limited",
            retry_after=retry_after,
        )


class InvalidCode(AuthError):
    def __init__(self) -> None:
        super().__init__("The code is invalid or has expired.", code="invalid_code")


class InvalidSession(AuthError):
    def __init__(self) -> None:
        super().__init__("Authentication is required.", status_code=401, code="unauthorized")


class AccountDeleted(AuthError):
    def __init__(self) -> None:
        super().__init__("This account has been deleted.", status_code=403, code="account_deleted")


def normalize_email(email: str) -> str:
    return email.strip().lower()


def hash_code(secret: str, email: str, code: str) -> str:
    payload = f"{email}:{code}".encode()
    return hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _new_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


async def request_auth_code(
    session: AsyncSession,
    email: str,
    sender: EmailSender,
    settings: Settings,
) -> tuple[int, int]:
    normalized = normalize_email(email)
    now = utcnow()

    account = await session.scalar(select(Account).where(Account.email == normalized))
    if account is not None and account.deleted_at is not None:
        raise AccountDeleted()

    latest = await session.scalar(
        select(AuthCode)
        .where(AuthCode.email == normalized)
        .order_by(AuthCode.created_at.desc())
        .limit(1)
    )
    if latest is not None:
        elapsed = (now - latest.created_at).total_seconds()
        if elapsed < settings.auth_code_resend_cooldown_seconds:
            raise RateLimited(int(settings.auth_code_resend_cooldown_seconds - elapsed) + 1)

    hourly_count = await session.scalar(
        select(func.count())
        .select_from(AuthCode)
        .where(
            AuthCode.email == normalized,
            AuthCode.created_at > now - timedelta(hours=1),
        )
    )
    if (hourly_count or 0) >= settings.auth_code_max_per_hour:
        raise RateLimited(3600)

    previous = await session.scalars(
        select(AuthCode).where(
            AuthCode.email == normalized,
            AuthCode.consumed_at.is_(None),
        )
    )
    for row in previous:
        row.consumed_at = now

    code = _new_code()
    auth_code = AuthCode(
        email=normalized,
        code_hash=hash_code(settings.auth_secret, normalized, code),
        expires_at=now + timedelta(seconds=settings.auth_code_ttl_seconds),
    )
    session.add(auth_code)
    await session.flush()

    try:
        await sender.send_code(normalized, code)
    except Exception as exc:
        await session.rollback()
        raise AuthError(
            "Could not send the verification code.",
            status_code=502,
            code="email_delivery_failed",
        ) from exc

    await session.commit()
    return settings.auth_code_ttl_seconds, settings.auth_code_resend_cooldown_seconds


async def verify_auth_code(
    session: AsyncSession,
    email: str,
    code: str,
    settings: Settings,
    initial_soul: InitialSoul | None = None,
) -> tuple[str, Account, bool]:
    normalized = normalize_email(email)
    now = utcnow()

    auth_code = await session.scalar(
        select(AuthCode)
        .where(
            AuthCode.email == normalized,
            AuthCode.consumed_at.is_(None),
        )
        .order_by(AuthCode.created_at.desc())
        .limit(1)
    )
    if auth_code is None or auth_code.expires_at < now:
        raise InvalidCode()
    if auth_code.attempts >= settings.auth_code_max_attempts:
        raise InvalidCode()

    expected = hash_code(settings.auth_secret, normalized, code)
    if not hmac.compare_digest(auth_code.code_hash, expected):
        auth_code.attempts += 1
        await session.commit()
        raise InvalidCode()

    auth_code.consumed_at = now

    account = await session.scalar(select(Account).where(Account.email == normalized))
    is_new = account is None
    if account is None:
        account = Account(email=normalized)
        session.add(account)
        await session.flush()
    elif account.deleted_at is not None:
        raise AccountDeleted()

    profile = await session.get(SoulProfile, account.id)
    if profile is None:
        if initial_soul is None:
            raise AuthError(
                "A native language is required for a new account.",
                code="native_language_required",
            )
        await bind_initial_soul(session, account.id, initial_soul)

    token = secrets.token_urlsafe(32)
    auth_session = AuthSession(
        account_id=account.id,
        token_hash=hash_token(token),
        expires_at=now + timedelta(days=settings.auth_session_ttl_days),
    )
    session.add(auth_session)
    await session.commit()
    return token, account, is_new


async def authenticate_session(
    session: AsyncSession,
    token: str,
    settings: Settings,
) -> tuple[AuthSession, Account]:
    if not token:
        raise InvalidSession()

    now = utcnow()
    auth_session = await session.scalar(
        select(AuthSession).where(AuthSession.token_hash == hash_token(token))
    )
    if auth_session is None or auth_session.revoked_at is not None:
        raise InvalidSession()
    if auth_session.expires_at < now:
        raise InvalidSession()

    account = await session.get(Account, auth_session.account_id)
    if account is None or account.deleted_at is not None:
        raise InvalidSession()

    auth_session.last_seen_at = now
    if auth_session.expires_at < now + timedelta(days=settings.auth_session_ttl_days - 1):
        auth_session.expires_at = now + timedelta(days=settings.auth_session_ttl_days)
    await session.commit()

    return auth_session, account


async def revoke_session(session: AsyncSession, auth_session: AuthSession) -> None:
    auth_session.revoked_at = utcnow()
    await session.commit()


async def schedule_account_deletion(session: AsyncSession, account: Account) -> datetime:
    now = utcnow()
    account.deleted_at = now
    account.deletion_scheduled_at = now + timedelta(days=30)
    await session.execute(
        update(AuthSession)
        .where(
            AuthSession.account_id == account.id,
            AuthSession.revoked_at.is_(None),
        )
        .values(revoked_at=now)
    )
    await session.commit()
    return account.deletion_scheduled_at
