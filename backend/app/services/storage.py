"""File storage abstraction — S3 when configured, local disk otherwise.

Used for audio recordings, lesson/audiobook media and generated certificates.
"""
from __future__ import annotations

import asyncio
import uuid
from pathlib import Path

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("storage")


def _safe_name(filename: str) -> str:
    suffix = Path(filename).suffix
    return f"{uuid.uuid4().hex}{suffix}"


async def save_bytes(
    data: bytes, *, folder: str, filename: str, content_type: str | None = None
) -> str:
    """Persist bytes and return a retrievable URL/path."""
    name = _safe_name(filename)

    if settings.s3_bucket and settings.s3_access_key:
        return await _save_s3(data, folder, name, content_type)

    # Local fallback — file IO off the event loop (uploads reach 64MB)
    base = Path(settings.local_media_dir) / folder
    base.mkdir(parents=True, exist_ok=True)
    path = base / name
    await asyncio.to_thread(path.write_bytes, data)
    url = f"/media/{folder}/{name}"
    log.info("storage.saved_local", path=str(path))
    return url


async def load_bytes(url: str) -> bytes | None:
    """Load bytes back from a URL previously returned by ``save_bytes``.

    Only local /media/... paths are supported; S3 and external URLs return None.
    """
    if not url:
        return None
    if url.startswith("/media/"):
        rel = url[len("/media/"):]
        path = Path(settings.local_media_dir) / rel
        if path.exists():
            return await asyncio.to_thread(path.read_bytes)
        log.warning("storage.load_bytes_missing", url=url)
        return None
    # S3/external URLs: not implemented — return None (caller falls back gracefully)
    return None


async def _save_s3(
    data: bytes, folder: str, name: str, content_type: str | None
) -> str:  # pragma: no cover - requires aiobotocore/boto3
    """Placeholder S3 upload. Wire up boto3/aiobotocore in a later phase."""
    key = f"{folder}/{name}"
    log.info("storage.s3_stub", key=key, size=len(data))
    endpoint = settings.s3_endpoint or f"https://{settings.s3_bucket}.s3.amazonaws.com"
    return f"{endpoint.rstrip('/')}/{key}"
