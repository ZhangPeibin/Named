import asyncio
from dataclasses import dataclass, field
from typing import Any


@dataclass
class FakeUsage:
    input_tokens: int = 0
    output_tokens: int = 0


@dataclass
class FakeRunResult:
    output: Any
    usage: FakeUsage = field(default_factory=FakeUsage)


@dataclass
class FakeAgent:
    outputs: list[Any] = field(default_factory=list)
    errors: list[BaseException] = field(default_factory=list)
    delay_seconds: float = 0.0
    calls: list[Any] = field(default_factory=list)

    async def run(self, prompt: Any, *, timeout: float | None = None) -> FakeRunResult:
        self.calls.append(prompt)

        async def execute() -> FakeRunResult:
            if self.delay_seconds:
                await asyncio.sleep(self.delay_seconds)
            if self.errors:
                raise self.errors.pop(0)
            if not self.outputs:
                raise AssertionError("FakeAgent has no output queued.")
            return FakeRunResult(output=self.outputs.pop(0))

        if timeout is None:
            return await execute()
        return await asyncio.wait_for(execute(), timeout=timeout)
