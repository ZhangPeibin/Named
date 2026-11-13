from agents.spec import AgentSpec
from errors import ApiError


class AgentFailed(Exception):
    def __init__(
        self,
        message: str = "The AI agent failed.",
        *,
        agent: str | None = None,
        attempts: int = 1,
    ) -> None:
        super().__init__(message)
        self.agent = agent
        self.attempts = attempts


class AgentTimeout(AgentFailed):
    pass


def agent_api_error(exc: AgentFailed, spec: AgentSpec) -> ApiError:
    return ApiError(spec.error_message, status_code=502, code=spec.error_code)
