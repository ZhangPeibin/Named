import logging
from typing import Protocol

from config import Settings, get_settings

logger = logging.getLogger(__name__)


class EmailSender(Protocol):
    async def send_code(self, email: str, code: str) -> None: ...


class LoggingEmailSender:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    async def send_code(self, email: str, code: str) -> None:
        # Never log the plaintext code. Local development can set
        # AUTH_FIXED_CODE when a known code is needed.
        logger.info("Auth code generated for %s", email)


def get_email_sender() -> EmailSender:
    return LoggingEmailSender(get_settings())
