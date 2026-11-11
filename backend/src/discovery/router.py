from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, File, Form, Query, Response, UploadFile, status
from sqlalchemy import select

from auth.router import CurrentAuthDep, SessionDep, SettingsDep
from discovery.agent import DiscoveryAgent, get_discovery_agent
from discovery.schemas import (
    DiscoveryOut,
    FocusRequest,
    TalkWordSave,
    WordOut,
    WordProgressOut,
    WordProgressUpdate,
    WordSaveOut,
    WordsResponse,
)
from discovery.service import (
    create_discovery,
    delete_discovery,
    focus_discovery,
    get_discovery,
    get_word,
    get_words,
    lookup_word,
    mark_word_reviewed,
    save_talk_word,
    set_word_known,
)
from discovery.word_lookup_agent import WordLookupAgent, get_word_lookup_agent
from errors import ApiError
from images import ImageError, process_image
from models import Discovery
from ratelimit import DiscoverRateLimitDep
from tts.deps import MediaStoreDep, SpeechAudioServiceDep, WordAudioServiceDep

router = APIRouter(prefix="/discoveries", tags=["discoveries"])
word_router = APIRouter(prefix="/words", tags=["words"])
image_router = APIRouter(prefix="/images", tags=["images"])

DiscoveryAgentDep = Annotated[DiscoveryAgent, Depends(get_discovery_agent)]
WordLookupAgentDep = Annotated[WordLookupAgent, Depends(get_word_lookup_agent)]


@router.post("", response_model=DiscoveryOut, status_code=status.HTTP_201_CREATED)
async def create(
    current: CurrentAuthDep,
    session: SessionDep,
    agent: DiscoveryAgentDep,
    settings: SettingsDep,
    audio_service: WordAudioServiceDep,
    speech_service: SpeechAudioServiceDep,
    store: MediaStoreDep,
    _: DiscoverRateLimitDep,
    text: Annotated[str | None, Form()] = None,
    context: Annotated[str | None, Form()] = None,
    image: Annotated[UploadFile | None, File()] = None,
) -> DiscoveryOut:
    image_bytes: bytes | None = None
    image_media_type: str | None = None
    image_key: str | None = None

    if image is not None:
        raw = await image.read()
        if len(raw) > settings.image_max_bytes:
            raise ApiError("Image is too large.", code="image_too_large")
        try:
            image_bytes, image_media_type, _, _ = process_image(raw, settings.image_max_dimension)
        except ImageError as exc:
            raise ApiError("Invalid image.", code="invalid_image") from exc
        image_key = f"discovery-images/{uuid4()}.jpg"
        await store.put(image_key, image_bytes, image_media_type)

    try:
        return await create_discovery(
            session,
            current.account.id,
            text,
            context,
            image_bytes,
            image_media_type,
            image_key,
            agent,
            settings,
            audio_service,
            speech_service,
        )
    except Exception:
        if image_key is not None:
            await store.delete(image_key)
        raise


@router.post("/{discovery_id}/focus", response_model=DiscoveryOut)
async def focus(
    discovery_id: str,
    payload: FocusRequest,
    current: CurrentAuthDep,
    session: SessionDep,
    agent: DiscoveryAgentDep,
    settings: SettingsDep,
    audio_service: WordAudioServiceDep,
    _: DiscoverRateLimitDep,
) -> DiscoveryOut:
    return await focus_discovery(
        session,
        current.account.id,
        discovery_id,
        payload,
        agent,
        settings,
        audio_service,
    )


@router.get("/{discovery_id}", response_model=DiscoveryOut)
async def read(
    discovery_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    audio_service: WordAudioServiceDep,
) -> DiscoveryOut:
    return await get_discovery(
        session,
        current.account.id,
        discovery_id,
        settings,
        audio_service,
    )


@router.delete("/{discovery_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove(
    discovery_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
    store: MediaStoreDep,
) -> Response:
    await delete_discovery(session, current.account.id, discovery_id, store)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@word_router.get("", response_model=WordsResponse)
async def read_words(
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    audio_service: WordAudioServiceDep,
) -> WordsResponse:
    return await get_words(session, current.account.id, settings, audio_service)


@word_router.post("/from-talk", response_model=WordSaveOut, status_code=status.HTTP_201_CREATED)
async def save_from_talk(
    payload: TalkWordSave,
    current: CurrentAuthDep,
    session: SessionDep,
) -> WordSaveOut:
    return await save_talk_word(session, current.account.id, payload)


@word_router.patch("/{word_id}/progress", response_model=WordProgressOut)
async def update_word_progress(
    word_id: str,
    payload: WordProgressUpdate,
    current: CurrentAuthDep,
    session: SessionDep,
) -> WordProgressOut:
    return await set_word_known(
        session,
        current.account.id,
        word_id,
        payload.known,
    )


@word_router.post("/{word_id}/reviewed", response_model=WordProgressOut)
async def review_word(
    word_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> WordProgressOut:
    return await mark_word_reviewed(session, current.account.id, word_id)


@word_router.get("/lookup", response_model=WordOut)
async def read_word_lookup(
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    audio_service: WordAudioServiceDep,
    lookup_agent: WordLookupAgentDep,
    content_agent: DiscoveryAgentDep,
    _: DiscoverRateLimitDep,
    text: Annotated[str, Query(min_length=1, max_length=100)],
) -> WordOut:
    return await lookup_word(
        session,
        current.account.id,
        text,
        settings,
        audio_service,
        lookup_agent,
        content_agent,
    )


@word_router.get("/{word_id}", response_model=WordOut)
async def read_word(
    word_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    audio_service: WordAudioServiceDep,
) -> WordOut:
    return await get_word(
        session,
        current.account.id,
        word_id,
        settings,
        audio_service,
    )


@image_router.get("/{key:path}")
async def read_image(
    key: str,
    current: CurrentAuthDep,
    session: SessionDep,
    store: MediaStoreDep,
) -> Response:
    owned = await session.scalar(
        select(Discovery.id)
        .where(
            Discovery.image_key == key,
            Discovery.account_id == current.account.id,
            Discovery.deleted_at.is_(None),
        )
        .limit(1)
    )
    if owned is None:
        raise ApiError("Image not found.", status_code=404, code="image_not_found")

    data = await store.get(key)
    if data is None:
        raise ApiError("Image not found.", status_code=404, code="image_not_found")
    return Response(
        content=data,
        media_type="image/jpeg",
        headers={"Cache-Control": "private, max-age=86400"},
    )
