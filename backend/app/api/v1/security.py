"""Security session API — the client uses these endpoints to:
  1) announce that a login just happened (start a tracked session);
  2) keep the session alive (heartbeat) and refresh the watermark;
  3) report security events (screen-capture attempt, root, …);
  4) close the session on logout.

Watermark text is server-generated so it cannot be forged by the client.
The token `jti` is read from the JWT when present so a server-side
invalidation list can be built.
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

import jwt
from fastapi import APIRouter, Depends, Request, UploadFile, File
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession
from app.core.config import settings
from app.core.exceptions import NotFoundError
from app.core.security import decode_token
from app.models.security_session import (
    SecurityEventType,
    SecuritySession,
    SecuritySessionEvent,
)
from app.schemas.security import (
    EventOut,
    SecurityEventIn,
    SessionDetailOut,
    SessionEndIn,
    SessionHeartbeatIn,
    SessionStartIn,
    SessionStartOut,
)
from app.services import security_service

router = APIRouter()


def _jti_from_request(request: Request) -> str | None:
    """Best-effort extraction of the JWT id from the Authorization header."""
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        return None
    token = auth[7:].strip()
    try:
        payload = decode_token(token)
        return str(payload.get("jti")) if payload.get("jti") else None
    except jwt.PyJWTError:
        return None


def _serialize(sess: SecuritySession) -> dict:
    return {
        "id": sess.id,
        "is_active": sess.is_active,
        "started_at": sess.started_at,
        "last_heartbeat_at": sess.last_heartbeat_at,
        "ended_at": sess.ended_at,
        "platform": sess.platform,
        "os_version": sess.os_version,
        "app_version": sess.app_version,
        "device_model": sess.device_model,
        "device_id": sess.device_id,
        "locale": sess.locale,
        "country": sess.country,
        "city": sess.city,
        "watermark_text": sess.watermark_text,
        "screen_capture_attempts": sess.screen_capture_attempts,
        "screenshot_attempts": sess.screenshot_attempts,
        "auto_recordings_uploaded": sess.auto_recordings_uploaded,
    }


@router.post("/sessions/start", response_model=SessionStartOut)
async def start_session(
    payload: SessionStartIn,
    request: Request,
    db: DbSession,
    user: CurrentUser,
) -> SessionStartOut:
    jti = _jti_from_request(request)
    sess = await security_service.start_session(
        db,
        user=user,
        token_jti=jti,
        platform=payload.platform,
        os_version=payload.os_version,
        app_version=payload.app_version,
        device_model=payload.device_model,
        device_id=payload.device_id,
        locale=payload.locale,
        ip=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )
    return SessionStartOut(
        session=_serialize(sess),
        watermark_text=sess.watermark_text or "",
        server_time=datetime.now(timezone.utc),
    )


@router.post("/sessions/{session_id}/heartbeat")
async def heartbeat(
    session_id: uuid.UUID,
    payload: SessionHeartbeatIn,
    db: DbSession,
    user: CurrentUser,
) -> dict:
    sess = await security_service.get_session(db, user=user, session_id=session_id)
    if sess is None:
        raise NotFoundError("Sessiya topilmadi.")
    sess = await security_service.heartbeat(
        db, session=sess, watermark_text=payload.watermark_text
    )
    return {"ok": True, "watermark_text": sess.watermark_text}


@router.post("/sessions/{session_id}/end")
async def end_session(
    session_id: uuid.UUID,
    payload: SessionEndIn,
    db: DbSession,
    user: CurrentUser,
) -> dict:
    sess = await security_service.get_session(db, user=user, session_id=session_id)
    if sess is None:
        raise NotFoundError("Sessiya topilmadi.")
    await security_service.end_session(db, session=sess, reason=payload.reason)
    return {"ok": True}


@router.post("/sessions/{session_id}/events", response_model=EventOut)
async def add_event(
    session_id: uuid.UUID,
    payload: SecurityEventIn,
    db: DbSession,
    user: CurrentUser,
) -> EventOut:
    sess = await security_service.get_session(db, user=user, session_id=session_id)
    if sess is None:
        raise NotFoundError("Sessiya topilmadi.")
    ev = await security_service.record_event(
        db, session=sess, type_=payload.type, payload=payload.payload, note=payload.note
    )
    return EventOut(
        id=ev.id or uuid.uuid4(),
        type=ev.type,
        payload=ev.payload,
        note=ev.note,
        created_at=ev.created_at or datetime.now(timezone.utc),
    )


@router.post("/sessions/{session_id}/recording")
async def upload_recording(
    session_id: uuid.UUID,
    db: DbSession,
    user: CurrentUser,
    file: UploadFile = File(...),
    kind: str = "audio",
    duration_sec: int = 0,
    note: str | None = None,
) -> dict:
    """Receive the short audio clip captured at login.

    The binary is persisted to `media/security/<session_id>.m4a` and the
    event log gets an `auto_recording_uploaded` row pointing at the file
    size. The audio itself is intentionally not transcribed server-side
    (privacy + cost); it serves as an identity-binding artifact only.
    """
    from pathlib import Path

    sess = await security_service.get_session(db, user=user, session_id=session_id)
    if sess is None:
        raise NotFoundError("Sessiya topilmadi.")

    media_root = Path(settings.local_media_dir) / "security"
    media_root.mkdir(parents=True, exist_ok=True)
    out = media_root / f"{session_id}.m4a"
    size = 0
    with out.open("wb") as fh:
        while chunk := await file.read(64 * 1024):
            fh.write(chunk)
            size += len(chunk)

    await security_service.record_event(
        db,
        session=sess,
        type_=SecurityEventType.auto_recording_uploaded,
        payload={
            "kind": kind,
            "duration_sec": duration_sec,
            "mime": file.content_type or "audio/m4a",
            "bytes": size,
            "path": str(out),
        },
        note=note,
    )
    return {"ok": True, "bytes": size, "path": str(out)}


@router.get("/sessions", response_model=list[dict])
async def list_my_sessions(
    active_only: bool = False,
    db: DbSession = None,
    user: CurrentUser = None,
) -> list[dict]:
    rows = await security_service.list_user_sessions(
        db, user=user, active_only=active_only
    )
    return [_serialize(r) for r in rows]


@router.get("/sessions/{session_id}", response_model=SessionDetailOut)
async def get_my_session(
    session_id: uuid.UUID,
    db: DbSession,
    user: CurrentUser,
) -> SessionDetailOut:
    sess = await security_service.get_session(db, user=user, session_id=session_id)
    if sess is None:
        raise NotFoundError("Sessiya topilmadi.")
    events = list(
        (
            await db.execute(
                select(SecuritySessionEvent).where(
                    SecuritySessionEvent.session_id == sess.id
                )
            )
        )
        .scalars()
        .all()
    )
    base = _serialize(sess)
    base["events"] = [
        EventOut(
            id=ev.id,
            type=ev.type,
            payload=ev.payload,
            note=ev.note,
            created_at=ev.created_at,
        )
        for ev in events
    ]
    return SessionDetailOut(**base)
