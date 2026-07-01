"""Smoke tests for the public auth config endpoint."""
from __future__ import annotations

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_auth_config_returns_public_settings():
    """`/auth/config` exposes the Google client id (safe-by-design — meant
    to be embedded in the public client). No auth header required."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        r = await client.get("/api/v1/auth/config")
    assert r.status_code == 200
    body = r.json()
    assert "google_client_id" in body
    assert isinstance(body["google_client_id"], str)
