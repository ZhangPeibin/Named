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
        if self.settings.auth_dev_log_codes:
            logger.info("Development auth code for %s: %s", email, code)
        else:
            logger.info("Auth code sent to %s", email)


def get_email_sender() -> EmailSender:
    return LoggingEmailSender(get_settings())
