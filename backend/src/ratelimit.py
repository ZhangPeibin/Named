import time
from threading import Lock
from typing import Annotated

from fastapi import Depends

from auth.router import CurrentAuthDep, SettingsDep
from errors import ApiError


class FixedWindowLimiter:
    def __init__(self) -> None:
        self._buckets: dict[str, tuple[float, int]] = {}
        self._lock = Lock()

    def check(self, key: str, limit: int, window_seconds: int = 60) -> int | None:
        now = time.monotonic()
        with self._lock:
            started_at, count = self._buckets.get(key, (now, 0))
            if now - started_at >= window_seconds:
                started_at, count = now, 0
            count += 1
            self._buckets[key] = (started_at, count)
            if count > limit:
                return max(1, int(window_seconds - (now - started_at)) + 1)
        return None


limiter = FixedWindowLimiter()


def enforce_discover_limit(current: CurrentAuthDep, settings: SettingsDep) -> None:
    retry_after = limiter.check(
        f"discover:{current.account.id}",
        settings.rate_limit_discover_per_minute,
    )
    if retry_after is not None:
        raise ApiError(
            "Too many discovery requests. Try again later.",
            status_code=429,
            code="rate_limited",
            retry_after=retry_after,
        )


def enforce_talk_limit(current: CurrentAuthDep, settings: SettingsDep) -> None:
    retry_after = limiter.check(
        f"talk:{current.account.id}",
        settings.rate_limit_talk_per_minute,
    )
    if retry_after is not None:
        raise ApiError(
            "Too many messages. Try again later.",
            status_code=429,
            code="rate_limited",
            retry_after=retry_after,
        )


DiscoverRateLimitDep = Annotated[None, Depends(enforce_discover_limit)]
TalkRateLimitDep = Annotated[None, Depends(enforce_talk_limit)]
