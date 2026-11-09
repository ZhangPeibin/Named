from typing import Annotated

from fastapi import APIRouter, Depends, status

from auth.router import CurrentAuthDep, SessionDep, SettingsDep
from ratelimit import TalkRateLimitDep
from talk.agent import HelpAgent, TalkAgent, get_help_agent, get_talk_agent
from talk.schemas import (
    ConversationCreate,
    ConversationOut,
    EndConversationOut,
    HelpRequest,
    HelpResponse,
    MessageCreate,
    TurnOut,
)
from talk.service import (
    create_conversation,
    end_conversation,
    get_conversation,
    help_expression,
    send_message,
)
from tts.deps import SpeechAudioServiceDep

router = APIRouter(prefix="/conversations", tags=["talk"])

TalkAgentDep = Annotated[TalkAgent, Depends(get_talk_agent)]
HelpAgentDep = Annotated[HelpAgent, Depends(get_help_agent)]


@router.post("", response_model=ConversationOut, status_code=status.HTTP_201_CREATED)
async def create(
    payload: ConversationCreate,
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
) -> ConversationOut:
    return await create_conversation(session, current.account.id, payload, settings)


@router.get("/{conversation_id}", response_model=ConversationOut)
async def read(
    conversation_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
) -> ConversationOut:
    return await get_conversation(session, current.account.id, conversation_id, settings)


@router.post("/{conversation_id}/messages", response_model=TurnOut)
async def post_message(
    conversation_id: str,
    payload: MessageCreate,
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    agent: TalkAgentDep,
    speech_service: SpeechAudioServiceDep,
    _: TalkRateLimitDep,
) -> TurnOut:
    return await send_message(
        session,
        current.account.id,
        conversation_id,
        payload,
        agent,
        speech_service,
        settings,
    )


@router.post("/{conversation_id}/end", response_model=EndConversationOut)
async def end(
    conversation_id: str,
    current: CurrentAuthDep,
    session: SessionDep,
) -> EndConversationOut:
    return await end_conversation(session, current.account.id, conversation_id)


@router.post("/{conversation_id}/help", response_model=HelpResponse)
async def help(
    conversation_id: str,
    payload: HelpRequest,
    current: CurrentAuthDep,
    session: SessionDep,
    settings: SettingsDep,
    agent: HelpAgentDep,
    speech_service: SpeechAudioServiceDep,
    _: TalkRateLimitDep,
) -> HelpResponse:
    return await help_expression(
        session,
        current.account.id,
        conversation_id,
        payload,
        agent,
        speech_service,
        settings,
    )
