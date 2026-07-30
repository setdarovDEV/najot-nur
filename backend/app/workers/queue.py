"""Job enqueueing — the API side of the arq queue.

Kept separate from the worker module so the API process never imports the
job implementations (and therefore never needs ffmpeg on its PATH).
"""
from __future__ import annotations

from typing import Any

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("queue")

_pool: Any = None


async def get_pool() -> Any:
    """Lazily create the shared arq Redis pool."""
    global _pool
    if _pool is None:
        from arq.connections import RedisSettings, create_pool

        _pool = await create_pool(RedisSettings.from_dsn(settings.redis_url))
    return _pool


async def close_pool() -> None:
    global _pool
    if _pool is not None:
        await _pool.aclose()
        _pool = None


async def enqueue_transcode(lesson_id: str, source_key: str) -> bool:
    """Queue an HLS transcode. Returns False if the job could not be queued.

    A failure here is not fatal: the lesson keeps its uploaded MP4 as the
    playback source, so the video still works — just without adaptive bitrate.
    """
    if not settings.video_transcode_enabled:
        return False
    try:
        pool = await get_pool()
        # job_id keyed on the lesson so a double-click on "upload" cannot
        # start two encodes of the same lesson at once.
        await pool.enqueue_job(
            "transcode_lesson_video",
            lesson_id,
            source_key,
            _job_id=f"transcode:{lesson_id}:{source_key}",
        )
        log.info("queue.transcode_enqueued", lesson_id=lesson_id)
        return True
    except Exception as exc:
        log.error("queue.transcode_failed", lesson_id=lesson_id, error=str(exc))
        return False
