import asyncio
import logging

from database import SessionFactory
from experience.agent import ExperienceAgent, get_experience_agent
from experience.service import process_due_experience_jobs

logger = logging.getLogger(__name__)


async def experience_worker_loop(
    stop: asyncio.Event,
    *,
    interval_seconds: float,
    agent: ExperienceAgent | None = None,
) -> None:
    from config import get_settings

    settings = get_settings()
    try:
        extractor = agent or get_experience_agent()
    except Exception:
        logger.warning("Experience worker disabled: AI provider unavailable")
        return
    while not stop.is_set():
        try:
            async with SessionFactory() as session:
                await process_due_experience_jobs(session, extractor, settings)
        except Exception:
            logger.warning("Experience worker iteration failed")
        try:
            await asyncio.wait_for(stop.wait(), timeout=interval_seconds)
        except TimeoutError:
            pass
