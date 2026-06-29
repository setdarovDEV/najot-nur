"""Orders API — manual payment zayavka (Click / Payme / Cash) for courses
and audiobooks. Admin approves → user is granted access."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query
from sqlalchemy import func, select

from app.api.deps import AdminUser, CurrentUser, DbSession
from app.core.exceptions import NotFoundError
from app.models.audiobook import Audiobook
from app.models.course import Course
from app.models.enums import OrderPaymentMethod, OrderPurpose, OrderStatus
from app.models.order import Order
from app.models.user import User
from app.schemas.common import Page
from app.schemas.order import OrderAdminAction, OrderAdminListItem, OrderCreate, OrderRead
from app.services import order_service

router = APIRouter()
admin_router = APIRouter()


# ──────────────────────────────────────────────
#  User: create & view own orders
# ──────────────────────────────────────────────


@router.post("/", response_model=OrderRead, status_code=201)
async def create_order(
    payload: OrderCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> Order:
    """Kurs yoki audiokitob sotib olish uchun zayavka yuborish."""
    return await order_service.create_order(
        db,
        user_id=current_user.id,
        purpose=payload.purpose,
        course_id=payload.course_id,
        audiobook_id=payload.audiobook_id,
        amount=float(payload.amount),
        payment_method=payload.payment_method,
        payment_proof_url=payload.payment_proof_url,
    )


@router.get("/my", response_model=Page[OrderRead])
async def my_orders(
    current_user: CurrentUser,
    db: DbSession,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=50),
) -> Page[OrderRead]:
    """Foydalanuvchining o'z zayavkalari."""
    base = select(Order).where(Order.user_id == current_user.id)
    total = (
        await db.execute(select(func.count()).select_from(base.subquery()))
    ).scalar_one()
    rows = (
        await db.execute(
            base.order_by(Order.created_at.desc()).offset((page - 1) * size).limit(size)
        )
    ).scalars().all()

    # Hydrate target_title from Course or Audiobook
    course_ids = {o.course_id for o in rows if o.course_id}
    audiobook_ids = {o.audiobook_id for o in rows if o.audiobook_id}

    course_titles: dict = {}
    if course_ids:
        course_rows = (
            await db.execute(
                select(Course.id, Course.title).where(Course.id.in_(course_ids))
            )
        ).all()
        course_titles = {cid: title for cid, title in course_rows}

    book_titles: dict = {}
    if audiobook_ids:
        book_rows = (
            await db.execute(
                select(Audiobook.id, Audiobook.title).where(
                    Audiobook.id.in_(audiobook_ids)
                )
            )
        ).all()
        book_titles = {bid: title for bid, title in book_rows}

    items: list[OrderRead] = []
    for o in rows:
        target_title = None
        if o.purpose == OrderPurpose.course and o.course_id:
            target_title = course_titles.get(o.course_id)
        elif o.purpose == OrderPurpose.audiobook and o.audiobook_id:
            target_title = book_titles.get(o.audiobook_id)
        items.append(
            OrderRead(
                id=o.id,
                user_id=o.user_id,
                purpose=o.purpose,
                course_id=o.course_id,
                audiobook_id=o.audiobook_id,
                amount=o.amount,
                currency=o.currency,
                payment_method=o.payment_method,
                status=o.status,
                payment_proof_url=o.payment_proof_url,
                admin_note=o.admin_note,
                reviewed_at=o.reviewed_at,
                reviewed_by=o.reviewed_by,
                created_at=o.created_at,
                target_title=target_title,
            )
        )

    return Page[OrderRead](items=items, total=total, page=page, size=size)


@router.get("/{order_id}", response_model=OrderRead)
async def get_order(
    order_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> Order:
    """Bitta zayavka holati."""
    order = await db.get(Order, order_id)
    if order is None or order.user_id != current_user.id:
        raise NotFoundError("Zayavka topilmadi.")
    return order


# ──────────────────────────────────────────────
#  Admin: list, approve, reject
# ──────────────────────────────────────────────


@admin_router.get("/orders", response_model=Page[OrderAdminListItem])
async def admin_list_orders(
    _: AdminUser,
    db: DbSession,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    status: OrderStatus | None = Query(None),
    payment_method: OrderPaymentMethod | None = Query(None),
    purpose: OrderPurpose | None = Query(None),
) -> Page[OrderAdminListItem]:
    """Barcha zayavkalar (filter: status, payment_method, purpose)."""
    base = select(Order)
    if status:
        base = base.where(Order.status == status)
    if payment_method:
        base = base.where(Order.payment_method == payment_method)
    if purpose:
        base = base.where(Order.purpose == purpose)

    total = (
        await db.execute(select(func.count()).select_from(base.subquery()))
    ).scalar_one()
    rows = (
        await db.execute(
            base.order_by(Order.created_at.desc()).offset((page - 1) * size).limit(size)
        )
    ).scalars().all()

    # Hydrate display fields: user contact + target title
    user_ids = {o.user_id for o in rows}
    course_ids = {o.course_id for o in rows if o.course_id}
    audiobook_ids = {o.audiobook_id for o in rows if o.audiobook_id}

    users_map: dict = {}
    if user_ids:
        user_rows = (
            await db.execute(select(User).where(User.id.in_(user_ids)))
        ).scalars().all()
        users_map = {u.id: u for u in user_rows}

    course_titles: dict = {}
    if course_ids:
        course_rows = (
            await db.execute(
                select(Course.id, Course.title).where(Course.id.in_(course_ids))
            )
        ).all()
        course_titles = {cid: title for cid, title in course_rows}

    book_titles: dict = {}
    if audiobook_ids:
        book_rows = (
            await db.execute(
                select(Audiobook.id, Audiobook.title).where(
                    Audiobook.id.in_(audiobook_ids)
                )
            )
        ).all()
        book_titles = {bid: title for bid, title in book_rows}

    items: list[OrderAdminListItem] = []
    for o in rows:
        user = users_map.get(o.user_id)
        target_title = None
        if o.purpose == OrderPurpose.course and o.course_id:
            target_title = course_titles.get(o.course_id)
        elif o.purpose == OrderPurpose.audiobook and o.audiobook_id:
            target_title = book_titles.get(o.audiobook_id)
        items.append(
            OrderAdminListItem(
                id=o.id,
                user_id=o.user_id,
                user_full_name=user.full_name if user else None,
                user_phone=user.phone if user else None,
                purpose=o.purpose,
                course_id=o.course_id,
                audiobook_id=o.audiobook_id,
                target_title=target_title,
                amount=o.amount,
                currency=o.currency,
                payment_method=o.payment_method,
                status=o.status,
                payment_proof_url=o.payment_proof_url,
                admin_note=o.admin_note,
                reviewed_at=o.reviewed_at,
                created_at=o.created_at,
            )
        )

    return Page[OrderAdminListItem](items=items, total=total, page=page, size=size)


@admin_router.patch("/orders/{order_id}/approve", response_model=OrderRead)
async def approve_order(
    order_id: uuid.UUID,
    payload: OrderAdminAction,
    admin: AdminUser,
    db: DbSession,
) -> Order:
    """Zayavkani tasdiqlash → kurs yoki audiokitob ochiladi."""
    return await order_service.approve_order(
        db,
        order_id=order_id,
        admin_id=admin.id,
        admin_note=payload.admin_note,
    )


@admin_router.patch("/orders/{order_id}/reject", response_model=OrderRead)
async def reject_order(
    order_id: uuid.UUID,
    payload: OrderAdminAction,
    admin: AdminUser,
    db: DbSession,
) -> Order:
    """Zayavkani rad etish."""
    return await order_service.reject_order(
        db,
        order_id=order_id,
        admin_id=admin.id,
        admin_note=payload.admin_note,
    )
