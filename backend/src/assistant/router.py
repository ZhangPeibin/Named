from typing import Annotated

from fastapi import APIRouter, Depends

from agents import AgentFailed, agent_api_error
from assistant.agent import SPEC as INTENT_SPEC
from assistant.agent import IntentAgent, get_intent_agent
from assistant.schemas import AssistantIntentOut, AssistantIntentRequest
from auth.router import CurrentAuthDep
from ratelimit import IntentRateLimitDep

router = APIRouter(prefix="/assistant", tags=["assistant"])
IntentAgentDep = Annotated[IntentAgent, Depends(get_intent_agent)]


@router.post("/route", response_model=AssistantIntentOut)
async def route_input(
    payload: AssistantIntentRequest,
    _: CurrentAuthDep,
    agent: IntentAgentDep,
    __: IntentRateLimitDep,
) -> AssistantIntentOut:
    try:
        return await agent.route(payload.text)
    except AgentFailed as exc:
        raise agent_api_error(exc, INTENT_SPEC) from exc
