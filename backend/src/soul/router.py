from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from auth.router import CurrentAuthDep
from database import get_session
from soul.schemas import (
    SoulItemCreate,
    SoulItemOut,
    SoulItemUpdate,
    SoulProfileOut,
    SoulResponse,
    SoulUpdate,
)
from soul.service import (
    create_item,
    delete_item,
    get_soul,
    update_item,
    update_soul,
)

router = APIRouter(prefix="/soul", tags=["soul"])

SessionDep = Annotated[AsyncSession, Depends(get_session)]


def _response(profile, items) -> SoulResponse:
    return SoulResponse(
        profile=SoulProfileOut.model_validate(profile),
        items=[SoulItemOut.model_validate(item) for item in items],
    )


@router.get("", response_model=SoulResponse)
async def read_soul(current: CurrentAuthDep, session: SessionDep) -> SoulResponse:
    profile, items = await get_soul(session, current.account.id)
    return _response(profile, items)


@router.patch("", response_model=SoulResponse)
async def patch_soul(
    payload: SoulUpdate,
    current: CurrentAuthDep,
    session: SessionDep,
) -> SoulResponse:
    profile, items = await update_soul(session, current.account.id, payload)
    return _response(profile, items)


@router.post("/items", response_model=SoulItemOut, status_code=status.HTTP_201_CREATED)
async def add_item(
    payload: SoulItemCreate,
    current: CurrentAuthDep,
    session: SessionDep,
) -> SoulItemOut:
    item = await create_item(session, current.account.id, payload)
    return SoulItemOut.model_validate(item)


@router.patch("/items/{item_id}", response_model=SoulItemOut)
async def patch_item(
    item_id: str,
    payload: SoulItemUpdate,
    current: CurrentAuthDep,
    session: SessionDep,
) -> SoulItemOut:
    item = await update_item(session, current.account.id, item_id, payload)
    return SoulItemOut.model_validate(item)


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_item(
    item_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> Response:
    await delete_item(session, current.account.id, item_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
