from dataclasses import dataclass

from pydantic import BaseModel


@dataclass(frozen=True, slots=True)
class AgentSpec[OutputT: BaseModel]:
    name: str
    output_type: type[OutputT]
    system_prompt: str
    prompt_version: str | None = None
    error_code: str = "agent_failed"
    error_message: str = "The AI agent failed."
    timeout_seconds: float | None = None
    max_attempts: int | None = None

    def __post_init__(self) -> None:
        if not self.name.strip():
            raise ValueError("AgentSpec name must not be empty.")
        if not self.system_prompt.strip():
            raise ValueError(f"AgentSpec {self.name} must have a system prompt.")
        if self.timeout_seconds is not None and self.timeout_seconds <= 0:
            raise ValueError(f"AgentSpec {self.name} timeout must be positive.")
        if self.max_attempts is not None and self.max_attempts < 1:
            raise ValueError(f"AgentSpec {self.name} max_attempts must be at least 1.")
