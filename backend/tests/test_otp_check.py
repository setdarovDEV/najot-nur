"""Tests for the multi-step phone registration flow.

The mobile client splits registration into three steps:
  1. POST /auth/otp/request  → generates a code, sends it via the
                                configured SMS provider (mock/eskiz) and
                                caches it in Redis
  2. POST /auth/otp/check    → verifies the code against the Redis cache
                                and marks the phone as verified
  3. POST /auth/otp/verify   → creates the user and issues the JWT pair
                                (re-verifies against Redis if the step-2
                                flag is missing)

These tests guard the schema and the SMS-provider integration.
"""
from __future__ import annotations

from unittest.mock import patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_otp_check_returns_valid_when_code_matches():
    """`/otp/check` returns valid when the code matches what was cached."""
    with patch("app.api.v1.auth.sms.verify_otp", return_value=True):
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
async def test_otp_request_returns_503_when_eskiz_not_configured():
    """With SMS_PROVIDER=eskiz but no ESKIZ_EMAIL / ESKIZ_PASSWORD,
    /otp/request must surface a clear 503 instead of crashing the request."""
    from app.core import config as cfg

    original_provider = cfg.settings.sms_provider
    original_email = cfg.settings.eskiz_email
    original_password = cfg.settings.eskiz_password
    cfg.settings.sms_provider = "eskiz"
    cfg.settings.eskiz_email = ""
    cfg.settings.eskiz_password = ""
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            r = await client.post(
                "/api/v1/auth/otp/request",
                json={"phone": "+998901112233"},
            )
    finally:
        cfg.settings.sms_provider = original_provider
        cfg.settings.eskiz_email = original_email
        cfg.settings.eskiz_password = original_password

    assert r.status_code == 503
    body = r.json()
    assert body["error"]["code"] == "eskiz_not_configured"
