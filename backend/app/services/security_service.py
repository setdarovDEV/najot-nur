"""Business logic for the security-session subsystem.

Centralises the watermarking policy, event recording and (best-effort) IP
geo-lookup. The service is purely async-friendly; FastAPI calls into it
through the router.
"""
from __future__ import annotations

import secrets
import uuid
from datetime import datetime, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.security_session import (
    SecurityEventType,
    SecuritySession,
    SecuritySessionEvent,
)
from app.models.user import User


# ───────────────────── helpers ─────────────────────
def _short_id() -> str:
    """6-char base32-ish tag for human-readable watermarks."""
    return secrets.token_hex(3).upper()


def build_watermark(*, user: User, device_id: str | None) -> str:
    """Compose the watermark string shown across the app.

    The text is intentionally hard to crop out: phone + short hash + a
    rotating token. Only a portion is rendered in the UI (tiled) so cropping
    is impractical.
    """
    phone = (user.phone or "")[-4:] or "----"
    tag = _short_id()
    suffix = (device_id or "noid")[:6]
    return f"{phone}·{tag}·{suffix}"


async def _best_effort_geo(ip: str | None) -> tuple[str | None, str | None]:
    """Stub IP→country/city lookup.

    The backend intentionally doesn't ship with a paid GeoIP DB; the field
    is reserved for a future plug-in (ipinfo, maxmind, …). Until then we
    return None for both values.
    """
    if not ip or ip in ("127.0.0.1", "::1"):
        return None, None
    return None, None


# ───────────────────── core operations ─────────────────────
async def start_session(
    db: AsyncSession,
    *,
    user: User,
    token_jti: str | None,
    platform: str,
    os_version: str | None,
    app_version: str | None,
    device_model: str | None,
    device_id: str | None,
    locale: str | None,
    ip: str | None,
    user_agent: str | None,
) -> SecuritySession:
    """Open a new active session and emit a `session_started` event."""
    country, city = await _best_effort_geo(ip)
    watermark = build_watermark(user=user, device_id=device_id)
    sess = SecuritySession(
        user_id=user.id,
        token_jti=token_jti,
        is_active=True,
        platform=platform[:16],
        os_version=(os_version or "")[:64] or None,
        app_version=(app_version or "")[:32] or None,
        device_model=(device_model or "")[:128] or None,
        device_id=(device_id or "")[:128] or None,
        locale=(locale or "")[:8] or None,
        ip_address=(ip or "")[:64] or None,
        user_agent=(user_agent or "")[:512] or None,
        country=country,
        city=city,
        watermark_text=watermark,
    )
    db.add(sess)
    await db.flush()
    db.add(
        SecuritySessionEvent(
            session_id=sess.id,
            type=SecurityEventType.session_started,
            payload={
                "platform": platform,
                "app_version": app_version,
                "os_version": os_version,
            },
        )
    )
    await db.commit()
    await db.refresh(sess)
    return sess


async def heartbeat(
    db: AsyncSession,
    *,
    session: SecuritySession,
    watermark_text: str | None,
) -> SecuritySession:
    """Refresh the heartbeat timestamp (and optionally the watermark)."""
    now = datetime.now(timezone.utc)
    values: dict = {"last_heartbeat_at": now}
    if watermark_text:
        values["watermark_text"] = watermark_text[:160]
    await db.execute(
        update(SecuritySession)
        .where(SecuritySession.id == session.id)
        .values(**values)
    )
    db.add(
        SecuritySessionEvent(
            session_id=session.id,
            type=SecurityEventType.session_heartbeat,
            payload={"watermark": watermark_text or session.watermark_text},
        )
    )
    await db.commit()
    await db.refresh(session)
    return session


async def end_session(
    db: AsyncSession,
    *,
    session: SecuritySession,
    reason: str | None = None,
) -> SecuritySession:
    now = datetime.now(timezone.utc)
    await db.execute(
        update(SecuritySession)
        .where(SecuritySession.id == session.id)
        .values(is_active=False, ended_at=now)
    )
    db.add(
        SecuritySessionEvent(
            session_id=session.id,
            type=SecurityEventType.session_ended,
            payload={},
            note=reason,
        )
    )
    await db.commit()
    await db.refresh(session)
    return session


async def record_event(
    db: AsyncSession,
    *,
    session: SecuritySession,
    type_: SecurityEventType,
    payload: dict | None = None,
    note: str | None = None,
) -> SecuritySessionEvent:
    """Append an event row and bump the matching counter on the session."""
    payload = payload or {}
    db.add(
        SecuritySessionEvent(
            session_id=session.id,
            type=type_,
            payload=payload,
            note=(note or "")[:512] or None,
        )
    )
    # Counter update — only a few of the events have dedicated counters.
    values: dict = {}
    if type_ == SecurityEventType.screen_capture_attempt:
        values["screen_capture_attempts"] = SecuritySession.screen_capture_attempts + 1
    elif type_ == SecurityEventType.screenshot_attempt:
        values["screenshot_attempts"] = SecuritySession.screenshot_attempts + 1
    elif type_ == SecurityEventType.auto_recording_uploaded:
        values["auto_recordings_uploaded"] = (
            SecuritySession.auto_recordings_uploaded + 1
        )
    if values:
        await db.execute(
            update(SecuritySession)
            .where(SecuritySession.id == session.id)
            .values(**values)
        )
    await db.commit()
    return SecuritySessionEvent(
        session_id=session.id, type=type_, payload=payload, note=note
    )


async def list_user_sessions(
    db: AsyncSession, *, user: User, active_only: bool = False
) -> list[SecuritySession]:
    stmt = select(SecuritySession).where(SecuritySession.user_id == user.id)
    if active_only:
        stmt = stmt.where(SecuritySession.is_active.is_(True))
    stmt = stmt.order_by(SecuritySession.started_at.desc())
    return list((await db.execute(stmt)).scalars().all())


async def get_session(
    db: AsyncSession, *, user: User, session_id: uuid.UUID
) -> SecuritySession | None:
    return (
        await db.execute(
            select(SecuritySession).where(
                SecuritySession.id == session_id,
                SecuritySession.user_id == user.id,
            )
        )
    ).scalar_one_or_none()


async def revoke_other_sessions(
    db: AsyncSession, *, user: User, keep_session_id: uuid.UUID
) -> int:
    """Deactivate every other active session for the same user."""
    res = await db.execute(
        update(SecuritySession)
        .where(
            SecuritySession.user_id == user.id,
            SecuritySession.is_active.is_(True),
            SecuritySession.id != keep_session_id,
        )
        .values(is_active=False, ended_at=datetime.now(timezone.utc))
    )
    return res.rowcount or 0
