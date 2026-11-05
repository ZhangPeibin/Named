from dataclasses import dataclass
from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from auth.schemas import (
    AccountDeletionOut,
    AccountOut,
    AuthCodeRequest,
    AuthCodeResponse,
    VerifyRequest,
    VerifyResponse,
)
from auth.service import (
    InvalidSession,
    authenticate_session,
    request_auth_code,
    revoke_session,
    schedule_account_deletion,
    verify_auth_code,
)
from config import Settings, get_settings
from database import get_session
from mailer import EmailSender, get_email_sender
from models import Account, AuthSession
from soul.schemas import SoulItemOut, SoulProfileOut, SoulResponse
from soul.service import get_soul

router = APIRouter(prefix="/auth", tags=["auth"])
me_router = APIRouter(tags=["auth"])

bearer = HTTPBearer(auto_error=False)

SessionDep = Annotated[AsyncSession, Depends(get_session)]
SettingsDep = Annotated[Settings, Depends(get_settings)]
EmailSenderDep = Annotated[EmailSender, Depends(get_email_sender)]
CredentialsDep = Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)]


@dataclass
class CurrentAuth:
    session: AuthSession
    account: Account


async def get_current_auth(
    credentials: CredentialsDep,
    session: SessionDep,
    settings: SettingsDep,
) -> CurrentAuth:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise InvalidSession()
    auth_session, account = await authenticate_session(session, credentials.credentials, settings)
    return CurrentAuth(session=auth_session, account=account)


CurrentAuthDep = Annotated[CurrentAuth, Depends(get_current_auth)]


@router.post("/code", response_model=AuthCodeResponse, status_code=status.HTTP_202_ACCEPTED)
async def create_auth_code(
    payload: AuthCodeRequest,
    session: SessionDep,
    sender: EmailSenderDep,
    settings: SettingsDep,
) -> AuthCodeResponse:
    expires_in, resend_after = await request_auth_code(session, payload.email, sender, settings)
    return AuthCodeResponse(expires_in=expires_in, resend_after=resend_after)


@router.post("/verify", response_model=VerifyResponse)
async def verify(
    payload: VerifyRequest,
    session: SessionDep,
    settings: SettingsDep,
) -> VerifyResponse:
    token, account, is_new = await verify_auth_code(
        session, payload.email, payload.code, settings, payload.initial_soul
    )
    profile, items = await get_soul(session, account.id)
    return VerifyResponse(
        session_token=token,
        account=AccountOut.model_validate(account),
        soul=SoulResponse(
            profile=SoulProfileOut.model_validate(profile),
            items=[SoulItemOut.model_validate(item) for item in items],
        ),
        is_new=is_new,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    current: CurrentAuthDep,
    session: SessionDep,
) -> Response:
    await revoke_session(session, current.session)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@me_router.get("/me", response_model=AccountOut)
async def me(current: CurrentAuthDep) -> AccountOut:
    return AccountOut.model_validate(current.account)


@me_router.delete(
    "/me",
    response_model=AccountDeletionOut,
    status_code=status.HTTP_202_ACCEPTED,
)
async def delete_me(
    current: CurrentAuthDep,
    session: SessionDep,
) -> AccountDeletionOut:
    scheduled_at = await schedule_account_deletion(session, current.account)
    return AccountDeletionOut(deletion_scheduled_at=scheduled_at)
