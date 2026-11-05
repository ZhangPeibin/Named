import asyncio
from pathlib import Path
from typing import Protocol

from config import get_settings


class MediaStore(Protocol):
    async def put(
        self, key: str, data: bytes, content_type: str = "application/octet-stream"
    ) -> None: ...

    async def get(self, key: str) -> bytes | None: ...

    async def exists(self, key: str) -> bool: ...

    async def delete(self, key: str) -> None: ...


class LocalMediaStore:
    def __init__(self, root: Path) -> None:
        self.root = root

    def _path(self, key: str) -> Path:
        root = self.root.resolve()
        path = (root / key).resolve()
        if path != root and root not in path.parents:
            raise ValueError("Invalid media key.")
        return path

    def _put(self, key: str, data: bytes) -> None:
        path = self._path(key)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

    def _get(self, key: str) -> bytes | None:
        path = self._path(key)
        if not path.is_file():
            return None
        return path.read_bytes()

    def _exists(self, key: str) -> bool:
        return self._path(key).is_file()

    def _delete(self, key: str) -> None:
        self._path(key).unlink(missing_ok=True)

    async def put(
        self, key: str, data: bytes, content_type: str = "application/octet-stream"
    ) -> None:
        await asyncio.to_thread(self._put, key, data)

    async def get(self, key: str) -> bytes | None:
        try:
            return await asyncio.to_thread(self._get, key)
        except ValueError:
            return None

    async def exists(self, key: str) -> bool:
        try:
            return await asyncio.to_thread(self._exists, key)
        except ValueError:
            return False

    async def delete(self, key: str) -> None:
        try:
            await asyncio.to_thread(self._delete, key)
        except ValueError:
            return


def get_media_store() -> MediaStore:
    return LocalMediaStore(Path(get_settings().media_root))
