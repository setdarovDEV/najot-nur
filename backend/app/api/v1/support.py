"""Support chat API — user-facing and admin/curator endpoints (HTTP + WS)."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CuratorUser, CurrentUser, DbSession
from app.core.database import AsyncSessionLocal
from app.core.security import decode_token
from app.core.ws_manager import connection_manager
from app.models.support import SupportMessage, SupportThreadRead
from app.models.user import User
from app.schemas.support import (
    SupportChatSummary,
    SupportMessageCreate,
    SupportMessageRead,
)

router = APIRouter()


# ───────────────────── Helpers ─────────────────────

async def _get_or_create_read_row(db: AsyncSession, user_id: uuid.UUID) -> SupportThreadRead:
    result = await db.execute(
        select(SupportThreadRead).where(SupportThreadRead.user_id == user_id)
    )
    row = result.scalar_one_or_none()
    if row is None:
        row = SupportThreadRead(user_id=user_id)
        db.add(row)
        await db.flush()
    return row


def _message_payload(msg: SupportMessage, *, event: str) -> dict:
    return {
        "event": event,
        "message": {
            "id": str(msg.id),
            "user_id": str(msg.user_id),
            "text": msg.text,
            "is_from_user": msg.is_from_user,
            "sent_by": str(msg.sent_by) if msg.sent_by else None,
            "created_at": msg.created_at.isoformat(),
        },
    }


def _chat_update_payload(
    *,
    user_id: uuid.UUID,
    last_message: str,
    last_message_at: datetime,
    unread_count: int,
) -> dict:
    return {
        "event": "chat_updated",
        "user_id": str(user_id),
        "last_message": last_message,
        "last_message_at": last_message_at.isoformat(),
        "unread_count": unread_count,
    }


async def _compute_unread_for_admins(
    db: AsyncSession, user_id: uuid.UUID
) -> int:
    """Count user messages in this thread that the admin side hasn't read yet."""
    result = await db.execute(
        select(SupportThreadRead).where(SupportThreadRead.user_id == user_id)
    )
    read_row = result.scalar_one_or_none()
    last_admin_read_at = read_row.last_admin_read_at if read_row else None
    stmt = select(func.count(SupportMessage.id)).where(
        SupportMessage.user_id == user_id,
        SupportMessage.is_from_user.is_(True),
    )
    if last_admin_read_at is not None:
        stmt = stmt.where(SupportMessage.created_at > last_admin_read_at)
    return (await db.execute(stmt)).scalar_one()


# ───────────────────── User endpoints ─────────────────────

@router.get("/messages", response_model=list[SupportMessageRead])
async def get_my_messages(current_user: CurrentUser, db: DbSession):
    """Return all messages in the current user's support thread."""
    result = await db.execute(
        select(SupportMessage)
        .where(SupportMessage.user_id == current_user.id)
        .order_by(SupportMessage.created_at.asc())
    )
    return result.scalars().all()


@router.post("/messages", response_model=SupportMessageRead, status_code=201)
async def send_message(
    body: SupportMessageCreate,
    current_user: CurrentUser,
    db: DbSession,
):
    """User sends a support message."""
    msg = SupportMessage(
        user_id=current_user.id,
        text=body.text,
        is_from_user=True,
        sent_by=current_user.id,
    )
    db.add(msg)
    await db.flush()

    # User just sent a message — they implicitly read everything up to now,
    # and admins have a fresh unread on this thread.
    read_row = await _get_or_create_read_row(db, current_user.id)
    read_row.last_user_read_at = msg.created_at

    await db.commit()
    await db.refresh(msg)

    unread = await _compute_unread_for_admins(db, current_user.id)
    await connection_manager.send_to_admins(
        _chat_update_payload(
            user_id=current_user.id,
            last_message=msg.text,
            last_message_at=msg.created_at,
            unread_count=unread,
        )
    )
    await connection_manager.send_to_admins(_message_payload(msg, event="new_message"))
    return msg


# ───────────────────── Admin / curator endpoints ─────────────────────

@router.get("/admin/chats", response_model=list[SupportChatSummary])
async def list_chats(_: CuratorUser, db: DbSession):
    """Return one row per user who has sent at least one message, newest first."""
    subq = (
        select(
            SupportMessage.user_id,
            func.max(SupportMessage.created_at).label("last_at"),
        )
        .group_by(SupportMessage.user_id)
        .subquery()
    )

    latest_text_subq = (
        select(
            SupportMessage.user_id,
            SupportMessage.text,
            SupportMessage.created_at,
        )
        .distinct(SupportMessage.user_id)
        .order_by(SupportMessage.user_id, SupportMessage.created_at.desc())
        .subquery()
    )

    rows = (
        await db.execute(
            select(
                User.id,
                User.full_name,
                User.phone,
                User.email,
                latest_text_subq.c.text,
                subq.c.last_at,
            )
            .join(subq, subq.c.user_id == User.id)
            .join(latest_text_subq, latest_text_subq.c.user_id == User.id)
            .order_by(subq.c.last_at.desc())
        )
    ).all()

    summaries: list[SupportChatSummary] = []
    for r in rows:
        uid = r[0]
        unread = await _compute_unread_for_admins(db, uid)
        summaries.append(
            SupportChatSummary(
                user_id=uid,
                full_name=r[1],
                phone=r[2],
                email=r[3],
                last_message=r[4],
                last_message_at=r[5],
                unread_count=unread,
            )
        )
    return summaries


@router.get(
    "/admin/chats/{user_id}/messages", response_model=list[SupportMessageRead]
)
async def get_user_chat(user_id: uuid.UUID, _: CuratorUser, db: DbSession):
    """Return all messages in a specific user's support thread."""
    result = await db.execute(
        select(SupportMessage)
        .where(SupportMessage.user_id == user_id)
        .order_by(SupportMessage.created_at.asc())
    )
    return result.scalars().all()


@router.post(
    "/admin/chats/{user_id}/read", status_code=204
)
async def mark_thread_read(
    user_id: uuid.UUID,
    current_user: CuratorUser,
    db: DbSession,
):
    """Mark all messages in the user's thread as read by the admin side.

    Called when the admin opens a chat (or whenever the admin client decides
    the thread is "in view"). Updates ``last_admin_read_at`` to ``now()``
    and broadcasts the refreshed ``unread_count`` to other admin clients.
    """
    if not await db.get(User, user_id):
        # No row to track — nothing to read.
        return

    read_row = await _get_or_create_read_row(db, user_id)
    read_row.last_admin_read_at = datetime.now(UTC)
    await db.commit()

    # Fetch the actual last message to include in the broadcast.
    last_msg_result = await db.execute(
        select(SupportMessage)
        .where(SupportMessage.user_id == user_id)
        .order_by(SupportMessage.created_at.desc())
        .limit(1)
    )
    last_msg = last_msg_result.scalar_one_or_none()

    await connection_manager.send_to_admins(
        _chat_update_payload(
            user_id=user_id,
            last_message=last_msg.text if last_msg else "",
            last_message_at=last_msg.created_at if last_msg else read_row.last_admin_read_at,
            unread_count=0,
        )
    )


@router.post(
    "/admin/chats/{user_id}/messages",
    response_model=SupportMessageRead,
    status_code=201,
)
async def reply_to_user(
    user_id: uuid.UUID,
    body: SupportMessageCreate,
    current_user: CuratorUser,
    db: DbSession,
):
    """Admin or curator replies in a user's support thread."""
    msg = SupportMessage(
        user_id=user_id,
        text=body.text,
        is_from_user=False,
        sent_by=current_user.id,
    )
    db.add(msg)
    await db.flush()

    # Bump admin's read cursor so this own message doesn't count as unread.
    read_row = await _get_or_create_read_row(db, user_id)
    read_row.last_admin_read_at = msg.created_at

    await db.commit()
    await db.refresh(msg)

    # Notify the user's mobile app (if connected).
    await connection_manager.send_to_user(
        user_id, _message_payload(msg, event="new_message")
    )
    # And tell every other admin the thread moved.
    await connection_manager.send_to_admins(
        _chat_update_payload(
            user_id=user_id,
            last_message=msg.text,
            last_message_at=msg.created_at,
            unread_count=0,
        )
    )
    await connection_manager.send_to_admins(_message_payload(msg, event="new_message"))
    return msg


# ───────────────────── WebSocket endpoints ─────────────────────

async def _authenticate_ws(
    websocket: WebSocket, token: str | None, db: AsyncSession
) -> User | None:
    """Verify the JWT carried as ``?token=`` and return the User, or close."""
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return None
    try:
        payload = decode_token(token)
    except Exception:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return None

    if payload.get("type") != "access":
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return None

    user = await db.get(User, uuid.UUID(payload["sub"]))
    if user is None or not user.is_active:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return None
    return user


@router.websocket("/ws")
async def user_ws(
    websocket: WebSocket, token: str | None = Query(default=None)
):
    """Mobile-user WebSocket. Receives new admin replies for its own thread.

    The connection stays open until the client disconnects; the server
    doesn't expect any inbound messages.
    """
    async with AsyncSessionLocal() as db:
        user = await _authenticate_ws(websocket, token, db)
        if user is None:
            return

        await connection_manager.connect_user(user.id, websocket)
        try:
            await websocket.send_json(
                {"event": "connected", "user_id": str(user.id)}
            )
            while True:
                # Discard whatever the client sends (we POST via HTTP).
                await websocket.receive_text()
        except WebSocketDisconnect:
            pass
        finally:
            await connection_manager.disconnect(websocket, user_id=user.id)


@router.websocket("/ws/admin")
async def admin_ws(
    websocket: WebSocket, token: str | None = Query(default=None)
):
    """Admin/curator WebSocket. Receives every support event."""
    from app.models.enums import Role

    async with AsyncSessionLocal() as db:
        user = await _authenticate_ws(websocket, token, db)
        if user is None:
            return
        if user.role not in (Role.curator, Role.admin):
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        await connection_manager.connect_admin(websocket)
        try:
            await websocket.send_json(
                {
                    "event": "connected",
                    "user_id": str(user.id),
                    "role": user.role.value,
                }
            )
            while True:
                await websocket.receive_text()
        except WebSocketDisconnect:
            pass
        finally:
            await connection_manager.disconnect(websocket)
