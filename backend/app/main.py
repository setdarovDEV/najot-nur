"""NotiqAI — FastAPI application entrypoint."""
from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.core.logging import configure_logging, get_logger
from app.core.middleware import RateLimitMiddleware, RequestContextMiddleware
from app.core.redis_client import close_redis, init_redis

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
    docs_url="/docs",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# ───── Middleware (order matters: last added runs first) ─────
app.add_middleware(RateLimitMiddleware, limit=240, window_seconds=60)
app.add_middleware(RequestContextMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID"],
)

register_exception_handlers(app)
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
