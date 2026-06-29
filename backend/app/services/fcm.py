"""Firebase Cloud Messaging (FCM) delivery service.

Gracefully degrades to a no-op when no service-account is configured — the
push endpoint will still write the notification to the DB so the mobile app
sees it through /users/me/notifications, but no device-tray push is sent.

Designed to be invoked from request handlers and to never block the response
on Firebase availability: if FCM is unreachable we log and return 0 success.
"""
from __future__ import annotations

import asyncio
import json
import os
from typing import Iterable

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("fcm")

_initialised = False
_messaging = None  # firebase_admin.messaging
_last_error: str | None = None


def _ensure_initialised() -> bool:
    """Initialise firebase-admin exactly once. Returns True if FCM is usable."""
    global _initialised, _messaging, _last_error

    if _initialised:
        return _messaging is not None

    _initialised = True

    if not settings.fcm_enabled:
        _last_error = "FCM_ENABLED=false in environment"
        log.info("fcm.disabled", reason=_last_error)
        return False

    if not settings.fcm_service_account_path or not os.path.isfile(
        settings.fcm_service_account_path
    ):
        _last_error = (
            f"Service account JSON topilmadi: {settings.fcm_service_account_path}. "
            f"Firebase konsolida yarating va FCM_SERVICE_ACCOUNT_PATH'ga ko'rsating."
        )
        log.error("fcm.missing_service_account", path=settings.fcm_service_account_path)
        return False

    try:
        import firebase_admin  # type: ignore
        from firebase_admin import credentials  # type: ignore
        from firebase_admin import messaging  # type: ignore
    except ImportError:
        _last_error = "firebase-admin paketi o'rnatilmagan (pip install firebase-admin)"
        log.error("fcm.import_missing")
        return False

    try:
        if not firebase_admin._apps:  # type: ignore[attr-defined]
            cred = credentials.Certificate(settings.fcm_service_account_path)
            firebase_admin.initialize_app(cred)
        _messaging = messaging
        _last_error = None
        log.info("fcm.initialised", project=settings.fcm_project_id or "auto")
        return True
    except Exception as exc:  # noqa: BLE001
        _last_error = f"FCM init xatosi: {exc}"
        log.error("fcm.init_failed", error=str(exc))
        _messaging = None
        return False


def status() -> dict:
    """Return FCM configuration status for diagnostics / admin panel."""
    path = settings.fcm_service_account_path
    return {
        "enabled": settings.fcm_enabled,
        "configured": _ensure_initialised(),
        "service_account_path": path,
        "service_account_exists": bool(path and os.path.isfile(path)),
        "project_id": settings.fcm_project_id or None,
        "last_error": _last_error,
    }


def _send_sync(tokens: list[str], title: str, body: str, data: dict) -> dict:
    """Blocking send. Runs inside an executor from the async wrapper below."""
    if not _ensure_initialised() or _messaging is None:
        return {"success": 0, "failure": 0, "invalid": []}

    msg = _messaging.MulticastMessage(
        notification=_messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in data.items()},
        tokens=tokens,
    )
    try:
        resp = _messaging.send_each_for_multicast(msg)
    except Exception as exc:  # noqa: BLE001
        log.error("fcm.send_failed", error=str(exc), n=len(tokens))
        return {"success": 0, "failure": len(tokens), "invalid": []}

    invalid: list[str] = []
    for idx, r in enumerate(resp.responses):
        if not r.success and r.exception is not None:
            code = getattr(r.exception, "code", "")
            # Unregistered / invalid-argument means the token is dead and the
            # mobile app should clean it up. FCM v1 codes: NOT_FOUND,
            # INVALID_ARGUMENT, UNREGISTERED.
            if code in {
                "messaging/registration-token-not-registered",
                "messaging/invalid-registration-token",
                "messaging/invalid-argument",
            }:
                invalid.append(tokens[idx])

    return {
        "success": resp.success_count,
        "failure": resp.failure_count,
        "invalid": invalid,
    }


async def send_to_tokens(
    tokens: Iterable[str],
    *,
    title: str,
    body: str,
    data: dict | None = None,
) -> dict:
    """Send a single notification to many device tokens.

    Returns ``{"success": int, "failure": int, "invalid": [token, ...]}``.
    FCM chunking: the HTTP v1 API allows up to 500 tokens per multicast, we
    iterate to be safe.
    """
    payload = {
        "title": title,
        "body": body,
        **(data or {}),
    }
    token_list = [t for t in tokens if t]
    if not token_list:
        return {"success": 0, "failure": 0, "invalid": []}

    if not _ensure_initialised():
        # Degraded mode: pretend we delivered so the UI doesn't show 0
        # success. The user will still see the message inside the app.
        log.info("fcm.skip_degraded", n=len(token_list), title=title, reason=_last_error)
        return {"success": 0, "failure": 0, "invalid": []}

    total = {"success": 0, "failure": 0, "invalid": []}
    chunk_size = 500
    loop = asyncio.get_running_loop()
    for i in range(0, len(token_list), chunk_size):
        chunk = token_list[i : i + chunk_size]
        result = await loop.run_in_executor(
            None, _send_sync, chunk, title, body, payload
        )
        total["success"] += result["success"]
        total["failure"] += result["failure"]
        total["invalid"].extend(result["invalid"])

    log.info(
        "fcm.sent",
        n=len(token_list),
        success=total["success"],
        failure=total["failure"],
        invalid=len(total["invalid"]),
    )
    return total
