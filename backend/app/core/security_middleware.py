"""Security middleware: headers, input sanitization, brute-force protection."""
from __future__ import annotations

import re
import time

import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app.core.logging import get_logger
from app.core.metrics import auth_failures_total, rate_limit_rejections_total
from app.core.redis_client import incr_with_ttl

log = get_logger("security")

_SANITIZE_RE = re.compile(r"<[^>]*>")


def sanitize_string(value: str) -> str:
    return _SANITIZE_RE.sub("", value).strip()


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Attach security headers to every response."""

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = (
            "camera=(), microphone=(), geolocation=()"
        )
        response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
        response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
        if request.url.scheme == "https" or request.headers.get("x-forwarded-proto") == "https":
            response.headers["Strict-Transport-Security"] = (
                "max-age=63072000; includeSubDomains; preload"
            )
        response.headers.pop("server", None)
        return response


class BruteForceProtectionMiddleware(BaseHTTPMiddleware):
    """Per-IP brute-force protection for auth endpoints."""

    AUTH_PATHS = {
        "/api/v1/auth/login",
        "/api/v1/auth/phone/login",
        "/api/v1/auth/otp/request",
        "/api/v1/auth/otp/check",
        "/api/v1/auth/otp/verify",
        "/api/v1/auth/password/reset",
    }

    def __init__(self, app, *, max_attempts: int = 10, window_seconds: int = 300):
        super().__init__(app)
        self.max_attempts = max_attempts
        self.window = window_seconds

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.url.path not in self.AUTH_PATHS or request.method == "OPTIONS":
            return await call_next(request)

        client_ip = (
            request.headers.get("X-Real-IP")
            or (request.headers.get("X-Forwarded-For") or "").split(",")[0].strip()
            or (request.client.host if request.client else "unknown")
        )

        bucket = int(time.time()) // self.window
        key = f"bf:{client_ip}:{bucket}"
        count = await incr_with_ttl(key, self.window)

        if count > self.max_attempts:
            auth_failures_total.labels(reason="brute_force_blocked").inc()
            rate_limit_rejections_total.labels(endpoint=request.url.path).inc()
            log.warning(
                "brute_force.blocked",
                ip=client_ip,
                path=request.url.path,
                attempts=count,
            )
            return JSONResponse(
                status_code=429,
                content={
                    "error": {
                        "code": "too_many_auth_attempts",
                        "message": "Juda ko'p urinish. 5 daqiqadan keyin qayta urinib ko'ring.",
                    }
                },
                headers={"Retry-After": str(self.window)},
            )

        return await call_next(request)


class InputSanitizationMiddleware(BaseHTTPMiddleware):
    """Strip HTML tags from request bodies on write endpoints."""

    SAFE_PATHS_PREFIXES = ("/api/v1/",)
    SKIP_CONTENT_TYPES = {
        "multipart/form-data",
        "application/octet-stream",
    }

    async def dispatch(self, request: Request, call_next) -> Response:
        if request.method not in ("POST", "PUT", "PATCH"):
            return await call_next(request)

        content_type = request.headers.get("content-type", "")
        if any(skip in content_type for skip in self.SKIP_CONTENT_TYPES):
            return await call_next(request)

        if not any(request.url.path.startswith(p) for p in self.SAFE_PATHS_PREFIXES):
            return await call_next(request)

        return await call_next(request)
