"""Advanced per-endpoint rate limiting backed by Redis.

Supports different limits for different endpoint groups (auth, AI analysis,
general API) and uses a sliding window approach for smoother throttling.
"""
from __future__ import annotations

import time

from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app.core.logging import get_logger
from app.core.metrics import rate_limit_rejections_total
from app.core.redis_client import get_redis

log = get_logger("rate_limit")

ENDPOINT_LIMITS: dict[str, dict[str, int]] = {
    "/api/v1/auth/otp/request": {"limit": 5, "window": 60},
    "/api/v1/auth/otp/check": {"limit": 10, "window": 60},
    "/api/v1/auth/otp/verify": {"limit": 5, "window": 60},
    "/api/v1/auth/login": {"limit": 10, "window": 60},
    "/api/v1/auth/phone/login": {"limit": 10, "window": 60},
    "/api/v1/auth/password/reset": {"limit": 3, "window": 300},
    "/api/v1/auth/google": {"limit": 10, "window": 60},
    "/api/v1/auth/refresh": {"limit": 30, "window": 60},
    "/api/v1/speech/": {"limit": 20, "window": 60},
    "/api/v1/observation/": {"limit": 20, "window": 60},
    "/api/v1/support/": {"limit": 30, "window": 60},
    "/api/v1/users/me/notifications": {"limit": 30, "window": 60},
}

DEFAULT_LIMIT = 120
DEFAULT_WINDOW = 60


def _get_client_ip(request: Request) -> str:
    return (
        request.headers.get("X-Real-IP")
        or (request.headers.get("X-Forwarded-For") or "").split(",")[0].strip()
        or (request.client.host if request.client else "unknown")
    )


def _match_limit(path: str) -> tuple[int, int]:
    for prefix, cfg in ENDPOINT_LIMITS.items():
        if path.startswith(prefix) or path == prefix:
            return cfg["limit"], cfg["window"]
    return DEFAULT_LIMIT, DEFAULT_WINDOW


async def sliding_window_check(
    key: str, limit: int, window: int
) -> tuple[bool, int]:
    """Sliding window rate limit check using Redis sorted sets.

    Returns (is_allowed, current_count).
    """
    r = get_redis()
    if r is None:
        return True, 0

    now = time.time()
    window_start = now - window

    try:
        pipe = r.pipeline()
        pipe.zremrangebyscore(key, 0, window_start)
        pipe.zadd(key, {str(now): now})
        pipe.zcard(key)
        pipe.expire(key, window + 1)
        results = await pipe.execute()
        count = int(results[2])
        return count <= limit, count
    except Exception as exc:
        log.warning("rate_limit.redis_error", error=str(exc))
        return True, 0


async def check_endpoint_rate_limit(request: Request) -> Response | None:
    """Check per-endpoint rate limits. Returns a 429 response or None."""
    if request.method == "OPTIONS":
        return None

    path = request.url.path
    if path in {"/health", "/", "/docs", "/openapi.json", "/metrics"}:
        return None

    limit, window = _match_limit(path)
    client_ip = _get_client_ip(request)

    bucket = int(time.time()) // window
    key = f"rl2:{client_ip}:{path}:{bucket}"

    r = get_redis()
    if r is None:
        return None

    try:
        pipe = r.pipeline()
        pipe.incr(key)
        pipe.expire(key, window + 1)
        results = await pipe.execute()
        count = int(results[0])

        if count > limit:
            rate_limit_rejections_total.labels(endpoint=path).inc()
            log.warning(
                "rate_limit.exceeded",
                ip=client_ip,
                path=path,
                count=count,
                limit=limit,
            )
            return JSONResponse(
                status_code=429,
                content={
                    "error": {
                        "code": "rate_limited",
                        "message": "Juda ko'p so'rov. Birozdan keyin qayta urinib ko'ring.",
                        "retry_after": window,
                    }
                },
                headers={
                    "Retry-After": str(window),
                    "X-RateLimit-Limit": str(limit),
                    "X-RateLimit-Remaining": "0",
                },
            )
    except Exception as exc:
        log.warning("rate_limit.check_error", error=str(exc))

    return None
