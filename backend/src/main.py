import asyncio
import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from starlette.exceptions import HTTPException as StarletteHTTPException

from auth.router import me_router
from auth.router import router as auth_router
from config import get_settings
from database import engine
from discovery.router import image_router, word_router
from discovery.router import router as discovery_router
from errors import ApiError
from experience.router import experience_router, history_router
from experience.worker import experience_worker_loop
from soul.router import router as soul_router
from stt.router import router as stt_router
from talk.router import router as talk_router
from timeline.router import router as timeline_router
from translation.router import router as translation_router
from tts.router import audio_router

settings = get_settings()
if settings.auth_dev_log_codes:
    logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("named.request")


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    stop_worker = asyncio.Event()
    worker = None
    if settings.experience_worker_enabled:
        worker = asyncio.create_task(
            experience_worker_loop(
                stop_worker,
                interval_seconds=settings.experience_worker_interval_seconds,
            )
        )
    yield
    if worker is not None:
        stop_worker.set()
        worker.cancel()
        with suppress(asyncio.CancelledError):
            await worker
    await engine.dispose()


app = FastAPI(title=settings.app_name, lifespan=lifespan)


def _request_id(request: Request) -> str:
    return getattr(request.state, "request_id", str(uuid4()))


def _problem(
    request: Request,
    status_code: int,
    code: str,
    detail: str,
    *,
    errors: list[dict] | None = None,
    retry_after: int | None = None,
) -> JSONResponse:
    content = {
        "type": "about:blank",
        "title": code.replace("_", " ").title(),
        "status": status_code,
        "detail": detail,
        "code": code,
        "request_id": _request_id(request),
    }
    if errors is not None:
        content["errors"] = errors
    headers = {}
    if retry_after is not None:
        headers["Retry-After"] = str(retry_after)
    return JSONResponse(
        status_code=status_code,
        content=content,
        media_type="application/problem+json",
        headers=headers,
    )


@app.middleware("http")
async def request_context(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID") or str(uuid4())
    request.state.request_id = request_id
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    logger.info(
        "%s %s -> %s request_id=%s",
        request.method,
        request.url.path,
        response.status_code,
        request_id,
    )
    return response


app.include_router(auth_router, prefix=settings.api_v1_prefix)
app.include_router(me_router, prefix=settings.api_v1_prefix)
app.include_router(soul_router, prefix=settings.api_v1_prefix)
app.include_router(discovery_router, prefix=settings.api_v1_prefix)
app.include_router(word_router, prefix=settings.api_v1_prefix)
app.include_router(image_router, prefix=settings.api_v1_prefix)
app.include_router(audio_router, prefix=settings.api_v1_prefix)
app.include_router(stt_router, prefix=settings.api_v1_prefix)
app.include_router(history_router, prefix=settings.api_v1_prefix)
app.include_router(experience_router, prefix=settings.api_v1_prefix)
app.include_router(translation_router, prefix=settings.api_v1_prefix)
app.include_router(talk_router, prefix=settings.api_v1_prefix)
app.include_router(timeline_router, prefix=settings.api_v1_prefix)


@app.exception_handler(ApiError)
async def api_error_handler(request: Request, exc: ApiError) -> JSONResponse:
    return _problem(
        request,
        exc.status_code,
        exc.code,
        exc.message,
        retry_after=exc.retry_after,
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    errors = [
        {
            "loc": list(error.get("loc", [])),
            "msg": error.get("msg", ""),
            "type": error.get("type", ""),
        }
        for error in exc.errors()
    ]
    return _problem(
        request,
        422,
        "validation_error",
        "Request validation failed.",
        errors=errors,
    )


@app.exception_handler(StarletteHTTPException)
async def http_error_handler(
    request: Request,
    exc: StarletteHTTPException,
) -> JSONResponse:
    return _problem(request, exc.status_code, "http_error", str(exc.detail))


@app.get("/health/live", tags=["health"])
async def live() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/ready", tags=["health"])
async def ready() -> dict[str, str]:
    try:
        async with engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"status": "unavailable"},
        ) from None
    return {"status": "ok"}
