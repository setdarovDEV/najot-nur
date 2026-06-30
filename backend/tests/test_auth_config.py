"""Smoke tests for the public auth config endpoint."""
from __future__ import annotations

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_auth_config_returns_public_settings():
    """`/auth/config` exposes the Telegram bot username + Google client id
    (both safe-by-design — they're meant to be embedded in the public
    client). No auth header required."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        r = await client.get("/api/v1/auth/config")
    assert r.status_code == 200
    body = r.json()
    assert "telegram_bot_username" in body
    assert "google_client_id" in body
    # Both values should be strings (may be empty in dev)
    assert isinstance(body["telegram_bot_username"], str)
    assert isinstance(body["google_client_id"], str)
