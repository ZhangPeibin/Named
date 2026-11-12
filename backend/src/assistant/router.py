from typing import Annotated

from fastapi import APIRouter, Depends

from assistant.agent import AgentFailed, IntentAgent, get_intent_agent
from assistant.schemas import AssistantIntentOut, AssistantIntentRequest
from auth.router import CurrentAuthDep
from errors import ApiError
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
        raise ApiError(
            "The assistant could not route this message.",
            status_code=502,
            code="agent_failed",
        ) from exc
