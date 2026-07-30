"""arq worker entrypoint:  arq app.workers.main.WorkerSettings

Runs as its own container (see the ``worker`` service in docker-compose) with
ffmpeg installed. Concurrency is deliberately low — transcoding is CPU-bound,
so running more jobs than cores just makes every one of them slower.
"""
from __future__ import annotations

from arq.connections import RedisSettings

from app.core.config import settings
from app.core.logging import configure_logging, get_logger
from app.services import storage
from app.workers.transcode import transcode_lesson_video

log = get_logger("worker")


async def startup(ctx: dict) -> None:
    configure_logging()
    log.info("worker.started", transcode_enabled=settings.video_transcode_enabled)


async def shutdown(ctx: dict) -> None:
    await storage.close_client()
    log.info("worker.stopped")


class WorkerSettings:
    functions = [transcode_lesson_video]
    on_startup = startup
    on_shutdown = shutdown
    redis_settings = RedisSettings.from_dsn(settings.redis_url)
    # One encode at a time per worker container; scale by adding replicas.
    max_jobs = 2
    # A 2GB source on a modest CPU can legitimately take well over an hour.
    job_timeout = 3 * 3600
    keep_result = 3600
    max_tries = 2
