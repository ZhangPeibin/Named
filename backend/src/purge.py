import asyncio
from pathlib import Path

from config import get_settings
from database import SessionFactory
from lifecycle import purge_expired_deletions
from media import LocalMediaStore


async def main() -> None:
    settings = get_settings()
    store = LocalMediaStore(Path(settings.media_root))
    async with SessionFactory() as session:
        purged = await purge_expired_deletions(session, store)
    print(f"Purged {purged} account(s).")


if __name__ == "__main__":
    asyncio.run(main())
