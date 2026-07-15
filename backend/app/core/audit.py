"""Audit logging — records security-relevant events to a structured log.

All audit entries go through structlog so they appear in JSON in production
and are picked up by Loki / any log aggregator.
"""
from __future__ import annotations

import uuid
from typing import Any

from app.core.logging import get_logger

log = get_logger("audit")


def audit(
    action: str,
    *,
    user_id: str | uuid.UUID | None = None,
    ip: str | None = None,
    user_agent: str | None = None,
    resource: str | None = None,
    resource_id: str | uuid.UUID | None = None,
    status: str = "success",
    details: dict[str, Any] | None = None,
) -> None:
    """Emit a structured audit log entry."""
    payload: dict[str, Any] = {
        "audit_action": action,
        "audit_status": status,
    }
    if user_id is not None:
        payload["audit_user_id"] = str(user_id)
    if ip is not None:
        payload["audit_ip"] = ip
    if user_agent is not None:
        payload["audit_user_agent"] = user_agent[:256]
    if resource is not None:
        payload["audit_resource"] = resource
    if resource_id is not None:
        payload["audit_resource_id"] = str(resource_id)
    if details:
        payload["audit_details"] = details

    log.info("audit.event", **payload)


def audit_auth(
    action: str,
    *,
    user_id: str | uuid.UUID | None = None,
    ip: str | None = None,
    user_agent: str | None = None,
    status: str = "success",
    reason: str | None = None,
) -> None:
    details = {}
    if reason:
        details["reason"] = reason
    audit(
        f"auth.{action}",
        user_id=user_id,
        ip=ip,
        user_agent=user_agent,
        status=status,
        details=details or None,
    )


def audit_admin(
    action: str,
    *,
    user_id: str | uuid.UUID,
    ip: str | None = None,
    resource: str | None = None,
    resource_id: str | uuid.UUID | None = None,
    status: str = "success",
    details: dict[str, Any] | None = None,
) -> None:
    audit(
        f"admin.{action}",
        user_id=user_id,
        ip=ip,
        resource=resource,
        resource_id=resource_id,
        status=status,
        details=details,
    )


def audit_security(
    event_type: str,
    *,
    user_id: str | uuid.UUID | None = None,
    session_id: str | uuid.UUID | None = None,
    ip: str | None = None,
    details: dict[str, Any] | None = None,
) -> None:
    audit(
        f"security.{event_type}",
        user_id=user_id,
        ip=ip,
        resource="security_session",
        resource_id=session_id,
        details=details,
    )
