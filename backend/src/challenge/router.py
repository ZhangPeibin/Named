from fastapi import APIRouter, status

from auth.router import CurrentAuthDep, SessionDep
from challenge.schemas import ChallengeCreate, ChallengeListOut, ChallengeOut
from challenge.service import (
    create_challenge,
    end_challenge,
    get_challenge,
    list_challenges,
    mark_visited,
)

router = APIRouter(prefix="/challenges", tags=["challenges"])


@router.get("", response_model=ChallengeListOut)
async def read_challenges(
    current: CurrentAuthDep,
    session: SessionDep,
) -> ChallengeListOut:
    return await list_challenges(session, current.account.id)


@router.post("", response_model=ChallengeOut, status_code=status.HTTP_201_CREATED)
async def create(
    payload: ChallengeCreate,
    current: CurrentAuthDep,
    session: SessionDep,
) -> ChallengeOut:
    return await create_challenge(session, current.account.id, payload)


@router.get("/{challenge_id}", response_model=ChallengeOut)
async def read(
    challenge_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> ChallengeOut:
    return await get_challenge(session, current.account.id, challenge_id)


@router.post("/{challenge_id}/items/{item_id}/visited", response_model=ChallengeOut)
async def visit(
    challenge_id: str,
    item_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> ChallengeOut:
    return await mark_visited(session, current.account.id, challenge_id, item_id)


@router.post("/{challenge_id}/end", response_model=ChallengeOut)
async def end(
    challenge_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> ChallengeOut:
    return await end_challenge(session, current.account.id, challenge_id)
