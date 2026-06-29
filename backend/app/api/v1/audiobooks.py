"""Audiobooks: listing, reader pages, per-user listening progress, and
per-user access checks (used by the mobile app to decide whether to show
the locked gate or the full player for a paid audiobook)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import selectinload

from app.api.deps import CurrentUser, DbSession
from app.core.exceptions import NotFoundError
from app.models.audiobook import (
    Audiobook,
    AudiobookAccess,
    AudiobookPage,
    AudiobookProgress,
)
from app.models.enums import OrderStatus
from app.models.order import Order
from app.schemas.audiobook import (
    AccessStatus,
    AudiobookDetail,
    AudiobookPageRead,
    AudiobookRead,
    ProgressUpdate,
)
from app.schemas.common import Message

router = APIRouter()


@router.get("", response_model=list[AudiobookRead])
async def list_audiobooks(db: DbSession, free_only: bool = False) -> list[Audiobook]:
    stmt = select(Audiobook).where(Audiobook.is_published.is_(True))
    if free_only:
        stmt = stmt.where(Audiobook.is_free.is_(True))
    rows = (await db.execute(stmt.order_by(Audiobook.created_at.desc()))).scalars().all()
    return list(rows)


@router.get("/{audiobook_id}", response_model=AudiobookDetail)
async def get_audiobook(audiobook_id: uuid.UUID, db: DbSession) -> Audiobook:
    book = (
        await db.execute(
            select(Audiobook)
            .where(Audiobook.id == audiobook_id)
            .options(selectinload(Audiobook.pages))
        )
    ).scalar_one_or_none()
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")
    return book


@router.get("/{audiobook_id}/pages/{page_number}", response_model=AudiobookPageRead)
async def get_page(
    audiobook_id: uuid.UUID, page_number: int, db: DbSession
) -> AudiobookPage:
    page = (
        await db.execute(
            select(AudiobookPage).where(
                AudiobookPage.audiobook_id == audiobook_id,
                AudiobookPage.page_number == page_number,
            )
        )
    ).scalar_one_or_none()
    if page is None:
        raise NotFoundError("Sahifa topilmadi.")
    return page


@router.post("/{audiobook_id}/progress", response_model=Message)
async def update_progress(
    audiobook_id: uuid.UUID,
    payload: ProgressUpdate,
    user: CurrentUser,
    db: DbSession,
) -> Message:
    stmt = (
        pg_insert(AudiobookProgress)
        .values(
            user_id=user.id,
            audiobook_id=audiobook_id,
            current_page=payload.current_page,
        )
        .on_conflict_do_update(
            constraint="user_audiobook",
            set_={"current_page": payload.current_page},
        )
    )
    await db.execute(stmt)
    return Message(message="Saqlandi.")


@router.get("/{audiobook_id}/access", response_model=AccessStatus)
async def check_access(
    audiobook_id: uuid.UUID,
    user: CurrentUser,
    db: DbSession,
) -> AccessStatus:
    """Should the mobile app show the locked gate or the player for this
    paid audiobook? Returns the access state for the current user."""
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")

    if book.is_free:
        return AccessStatus(
            state="granted", reason="free", has_pending_order=False
        )

    granted = (
        await db.execute(
            select(AudiobookAccess.id).where(
                AudiobookAccess.user_id == user.id,
                AudiobookAccess.audiobook_id == audiobook_id,
            )
        )
    ).scalar_one_or_none()
    if granted is not None:
        return AccessStatus(
            state="granted", reason="purchased", has_pending_order=False
        )

    pending = (
        await db.execute(
            select(Order.id).where(
                Order.user_id == user.id,
                Order.audiobook_id == audiobook_id,
                Order.status == OrderStatus.pending,
            )
        )
    ).scalar_one_or_none()

    return AccessStatus(
        state="locked",
        reason="pending" if pending else "none",
        has_pending_order=pending is not None,
    )
