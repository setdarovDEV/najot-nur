"""NotiqAI — FastAPI application entrypoint."""
from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.core.logging import configure_logging, get_logger
from app.core.middleware import RateLimitMiddleware, RequestContextMiddleware
from app.core.rate_limiter import check_endpoint_rate_limit
from app.core.redis_client import close_redis, init_redis
from app.core.security_middleware import (
    BruteForceProtectionMiddleware,
    InputSanitizationMiddleware,
    SecurityHeadersMiddleware,
)

configure_logging()
log = get_logger("app")


@asynccontextmanager
async def lifespan(_: FastAPI):
    log.info("app.startup", env=settings.environment, ai_enabled=settings.ai_enabled)
    await init_redis()
    yield
    await close_redis()
    log.info("app.shutdown")


app = FastAPI(
    title=f"{settings.app_name} API",
    version="0.1.0",
    description="AI-powered oratory training platform — Najot Nur",
    docs_url="/docs" if not settings.is_production else None,
    openapi_url="/openapi.json" if not settings.is_production else None,
    lifespan=lifespan,
)

# ───── Middleware (order matters: last added runs first) ─────
app.add_middleware(InputSanitizationMiddleware)
app.add_middleware(BruteForceProtectionMiddleware, max_attempts=15, window_seconds=300)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RateLimitMiddleware, limit=240, window_seconds=60)
app.add_middleware(RequestContextMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID", "X-RateLimit-Limit", "X-RateLimit-Remaining"],
)


@app.middleware("http")
async def per_endpoint_rate_limit(request: Request, call_next):
    blocked = await check_endpoint_rate_limit(request)
    if blocked is not None:
        return blocked
    return await call_next(request)


register_exception_handlers(app)

# ───── Prometheus metrics ─────
Instrumentator(
    should_group_status_codes_by_classes=True,
    should_ignore_untemplated=True,
    should_respect_env_var=False,
    env_var_name="ENABLE_METRICS",
    excluded_handlers=["/health", "/metrics"],
).instrument(app).expose(
    app,
    endpoint="/metrics",
    tags=["metrics"],
    include_in_schema=False,
    should_gzip=True,
)

app.include_router(api_router, prefix=settings.api_v1_prefix)

# Serve locally stored media (certificates, audio) when S3 is not configured.
_media_dir = Path(settings.local_media_dir)
_media_dir.mkdir(parents=True, exist_ok=True)
app.mount("/media", StaticFiles(directory=str(_media_dir)), name="media")


@app.get("/health", tags=["meta"])
async def health() -> dict:
    return {"status": "ok", "app": settings.app_name, "env": settings.environment}


@app.get("/", tags=["meta"])
async def root() -> dict:
    return {
        "name": f"{settings.app_name} API",
        "docs": "/docs",
        "version": "0.1.0",
    }
