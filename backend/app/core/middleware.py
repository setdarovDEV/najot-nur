"""HTTP middleware: request-id correlation, access logging, rate limiting."""
from __future__ import annotations

import time
import uuid

import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app.core.logging import get_logger
from app.core.redis_client import incr_with_ttl

log = get_logger("http")


class RequestContextMiddleware(BaseHTTPMiddleware):
    """Bind a request id, log timing, attach `X-Request-ID` to the response."""

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = request.headers.get("X-Request-ID", uuid.uuid4().hex)
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            request_id=request_id,
            method=request.method,
            path=request.url.path,
        )
        start = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            log.exception("request.failed")
            raise
        elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
        response.headers["X-Request-ID"] = request_id
        log.info("request.completed", status=response.status_code, ms=elapsed_ms)
        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Fixed-window per-IP rate limiter backed by Redis (fails open)."""

    def __init__(self, app, *, limit: int = 120, window_seconds: int = 60):
        super().__init__(app)
        self.limit = limit
        self.window = window_seconds

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.method == "OPTIONS" or request.url.path in {
            "/health",
            "/",
            "/docs",
            "/openapi.json",
        }:
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        bucket = int(time.time()) // self.window
        key = f"rl:{client_ip}:{bucket}"
        count = await incr_with_ttl(key, self.window)
        if count > self.limit:
            return JSONResponse(
                status_code=429,
                content={
                    "error": {
                        "code": "rate_limited",
                        "message": "Too many requests, try again later.",
                    }
                },
                headers={"Retry-After": str(self.window)},
            )
        return await call_next(request)
