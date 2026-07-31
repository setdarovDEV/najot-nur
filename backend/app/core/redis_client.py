"""Redis wrapper with graceful degradation.

If Redis is unreachable (e.g. local dev without it), calls degrade to no-ops
instead of crashing the app. Used for OTP storage, caching and rate limiting.
"""
from __future__ import annotations

import redis.asyncio as aioredis

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("redis")

_redis: aioredis.Redis | None = None


async def init_redis() -> None:
    global _redis
    try:
        _redis = aioredis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
            socket_connect_timeout=2,
        )
        await _redis.ping()
        log.info("redis.connected", url=settings.redis_url)
    except Exception as exc:  # pragma: no cover - depends on environment
        log.warning("redis.unavailable", error=str(exc))
        _redis = None


async def close_redis() -> None:
    if _redis is not None:
        await _redis.aclose()


def get_redis() -> aioredis.Redis | None:
    return _redis


async def cache_set(key: str, value: str, ttl: int | None = None) -> None:
    if _redis is None:
        return
    try:
        await _redis.set(key, value, ex=ttl)
    except Exception as exc:  # pragma: no cover - depends on environment
        log.warning("redis.cache_set_failed", key=key, error=str(exc))


async def cache_get(key: str) -> str | None:
    if _redis is None:
        return None
    try:
        return await _redis.get(key)
    except Exception as exc:  # pragma: no cover - depends on environment
        log.warning("redis.cache_get_failed", key=key, error=str(exc))
        return None


async def cache_delete(key: str) -> None:
    if _redis is None:
        return
    try:
        await _redis.delete(key)
    except Exception as exc:  # pragma: no cover - depends on environment
        log.warning("redis.cache_delete_failed", key=key, error=str(exc))


async def incr_with_ttl(key: str, ttl: int) -> int:
    """Atomic counter used for rate limiting. Returns current count.

    Returns 0 when Redis is unavailable (or errors) so rate limiting fails
    open instead of taking down every request behind it.
    """
    if _redis is None:
        return 0
    try:
        pipe = _redis.pipeline()
        pipe.incr(key)
        pipe.expire(key, ttl)
        result = await pipe.execute()
        return int(result[0])
    except Exception as exc:  # pragma: no cover - depends on environment
        log.warning("redis.incr_with_ttl_failed", key=key, error=str(exc))
        return 0
