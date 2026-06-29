"""Telegram Login Widget verification (HMAC over the data-check-string)."""
from __future__ import annotations

import hashlib
import hmac
import time

from app.core.config import settings
from app.core.exceptions import UnauthorizedError


def verify_telegram_auth(payload: dict) -> dict:
    """Validate the Telegram login payload signature and freshness.

    Returns {uid, name, username, photo}. Raises UnauthorizedError if invalid.
    """
    if not settings.telegram_bot_token:
        # Dev convenience: accept unverified payloads when no bot token is set.
        return {
            "uid": str(payload["id"]),
            "name": payload.get("first_name"),
            "username": payload.get("username"),
            "photo": payload.get("photo_url"),
        }

    received_hash = payload.get("hash", "")
    data = {k: v for k, v in payload.items() if k != "hash" and v is not None}
    check_string = "\n".join(f"{k}={data[k]}" for k in sorted(data))
    secret_key = hashlib.sha256(settings.telegram_bot_token.encode()).digest()
    expected = hmac.new(
        secret_key, check_string.encode(), hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(expected, received_hash):
        raise UnauthorizedError("Telegram imzosi yaroqsiz.")
    if time.time() - int(payload.get("auth_date", 0)) > 86400:
        raise UnauthorizedError("Telegram avtorizatsiyasi muddati o'tgan.")

    return {
        "uid": str(payload["id"]),
        "name": payload.get("first_name"),
        "username": payload.get("username"),
        "photo": payload.get("photo_url"),
    }
