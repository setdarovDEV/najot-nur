"""Tests for the multi-step phone registration flow.

The mobile client splits registration into three steps:
  1. POST /auth/otp/request  → asks Telegram's official
                                "Verification Codes" service to send a
                                6-digit code to the user's chat
  2. POST /auth/otp/check    → light format check only (does NOT call
                                Telegram — we want to avoid burning a
                                `signIn` for users who never finish
                                registration)
  3. POST /auth/otp/verify   → calls `auth.signIn` against Telegram,
                                finalises registration, creates the
                                user, issues the JWT pair

These tests guard the schema and the /check → /verify split.
"""
from __future__ import annotations

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_otp_check_returns_valid_for_any_well_formed_code():
    """`/otp/check` is a UX fast-path: it just confirms the user typed
    something that looks like a code. The real check happens in
    `/otp/verify` (and against Telegram)."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        r = await client.post(
            "/api/v1/auth/otp/check",
            json={"phone": "+998901112233", "code": "999999"},
        )
    assert r.status_code == 200
    body = r.json()
    assert body["valid"] is True


@pytest.mark.asyncio
async def test_otp_check_rejects_short_code():
    """Pydantic must reject codes shorter than 4 digits."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        r = await client.post(
            "/api/v1/auth/otp/check",
            json={"phone": "+998901112233", "code": "12"},
        )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_otp_check_validates_format():
    """Phone must match the E.164-ish pattern."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        r = await client.post(
            "/api/v1/auth/otp/check",
            json={"phone": "not-a-phone", "code": "123456"},
        )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_otp_request_returns_503_when_telegram_not_configured():
    """Without TELEGRAM_API_ID / TELEGRAM_API_HASH, /otp/request must
    surface a clear 503 instead of crashing the request."""
    from app.core import config as cfg

    original_id = cfg.settings.telegram_api_id
    original_hash = cfg.settings.telegram_api_hash
    cfg.settings.telegram_api_id = 0
    cfg.settings.telegram_api_hash = ""
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(
                "/api/v1/auth/otp/request",
                json={"phone": "+998901112233"},
            )
    finally:
        cfg.settings.telegram_api_id = original_id
        cfg.settings.telegram_api_hash = original_hash

    assert r.status_code == 503
    body = r.json()
    assert body["error"]["code"] == "telegram_login_not_configured"
