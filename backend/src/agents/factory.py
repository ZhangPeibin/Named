from functools import lru_cache

from agents.runtime import AgentRuntime
from ai import AINotConfigured, build_model, build_model_settings
from config import get_settings
from errors import ApiError


@lru_cache
def get_agent_runtime() -> AgentRuntime:
    settings = get_settings()
    try:
        model = build_model(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
    return AgentRuntime(model, build_model_settings(settings), settings)
