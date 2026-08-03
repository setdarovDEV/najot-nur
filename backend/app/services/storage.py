"""File storage abstraction — S3 when configured, local disk otherwise.

Used for audio recordings, lesson/audiobook media and generated certificates.
"""
from __future__ import annotations

import asyncio
import uuid
from pathlib import Path

from app.core.config import settings
from app.core.exceptions import AppError
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


async def save_stream(
    source,
    *,
    folder: str,
    filename: str,
    content_type: str | None = None,
    max_bytes: int | None = None,
) -> str:
    """Stream an upload to local disk without buffering it in memory.

    Reads ``source.read(chunk)`` in 1MB chunks and writes each chunk to a temp
    file before atomically renaming it into place. If ``max_bytes`` is set and
    the stream grows past it, a 413 ``AppError`` is raised and the temp file is
    removed. This keeps large video uploads within the container memory limit
    instead of calling ``file.read()`` and buffering the whole file in RAM.
    """
    name = _safe_name(filename)
    base = Path(settings.local_media_dir) / folder
    base.mkdir(parents=True, exist_ok=True)
    path = base / name
    tmp_path = path.with_name(path.name + ".part")

    total = 0
    try:
        with tmp_path.open("wb") as out:
            while True:
                chunk = await source.read(1024 * 1024)
                if not chunk:
                    break
                total += len(chunk)
                if max_bytes is not None and total > max_bytes:
                    limit_mb = max_bytes // (1024 * 1024)
                    raise AppError(
                        f"Fayl hajmi {limit_mb}MB dan oshmasligi kerak.",
                        status_code=413,
                        code="file_too_large",
                    )
                await asyncio.to_thread(out.write, chunk)
        tmp_path.replace(path)
    except BaseException:
        tmp_path.unlink(missing_ok=True)
        raise

    url = f"/media/{folder}/{name}"
    log.info("storage.saved_local_stream", path=str(path), size=total)
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
