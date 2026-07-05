"""Payment API: initiate payments, handle provider callbacks, admin reporting."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query, Request
from sqlalchemy import func, select

from app.api.deps import AdminUser, CurrentUser, DbSession
from app.core.exceptions import AppError, NotFoundError
from app.core.logging import get_logger
from app.models.enums import PaymentProvider, PaymentStatus
from app.models.payment import Payment
from app.schemas.common import Message, Page
from app.schemas.payment import (
    PaymentInitiate,
    PaymentInitiateResponse,
    PaymentListItem,
    PaymentRead,
)
from app.services import payment_service

# User-facing endpoints live under /payments (included in router.py with that prefix)
router = APIRouter()

# Admin endpoints live under /admin (included in router.py with that prefix)
admin_router = APIRouter()

log = get_logger("payments")


# ──────────────────────────────────────────────
#  User-facing: initiate payment
# ──────────────────────────────────────────────


@router.post("/initiate", response_model=PaymentInitiateResponse)
async def initiate_payment(
    payload: PaymentInitiate,
    current_user: CurrentUser,
    db: DbSession,
) -> PaymentInitiateResponse:
    """Initiate a payment with the chosen provider and return a redirect URL."""
    amount = float(payload.amount)

    if payload.provider == PaymentProvider.uzum:
        payment, redirect_url = await payment_service.initiate_uzum(
            db,
            user_id=current_user.id,
            amount=amount,
            reference_id=payload.reference_id,
            purpose=payload.purpose,
            return_url=payload.return_url,
        )

    elif payload.provider == PaymentProvider.uzum_nasiya:
        payment, redirect_url = await payment_service.initiate_uzum_nasiya(
            db,
            user_id=current_user.id,
            amount=amount,
            reference_id=payload.reference_id,
            purpose=payload.purpose,
            return_url=payload.return_url,
        )

    elif payload.provider == PaymentProvider.atmos:
        payment, redirect_url = await payment_service.initiate_atmos(
            db,
            user_id=current_user.id,
            amount=amount,
            reference_id=payload.reference_id,
            purpose=payload.purpose,
            return_url=payload.return_url,
        )

    else:
        raise AppError(f"Noto'g'ri provider: {payload.provider}", status_code=400)

    log.info(
        "payment.initiate",
        user_id=str(current_user.id),
        provider=payload.provider,
        payment_id=str(payment.id),
    )
    return PaymentInitiateResponse(
        payment_id=payment.id,
        redirect_url=redirect_url,
        status=payment.status,
    )


# ──────────────────────────────────────────────
#  Provider callbacks (no auth — public webhooks)
# ──────────────────────────────────────────────


@router.post("/uzum/callback", response_model=Message)
async def uzum_callback(request: Request, db: DbSession) -> Message:
    """Uzum payment webhook endpoint."""
    payload: dict = await request.json()
    log.info("uzum.callback", payload_keys=list(payload.keys()))
    payment = await payment_service.handle_uzum_callback(db, payload)
    return Message(message=f"OK: {payment.status}")


@router.post("/uzum-nasiya/callback", response_model=Message)
async def uzum_nasiya_callback(request: Request, db: DbSession) -> Message:
    """Uzum Nasiya installment webhook endpoint."""
    payload: dict = await request.json()
    log.info("uzum_nasiya.callback", payload_keys=list(payload.keys()))
    payment = await payment_service.handle_uzum_nasiya_callback(db, payload)
    return Message(message=f"OK: {payment.status}")


@router.post("/atmos/callback", response_model=Message)
async def atmos_callback(request: Request, db: DbSession) -> Message:
    """ATMOS payment webhook endpoint."""
    payload: dict = await request.json()
    log.info("atmos.callback", payload_keys=list(payload.keys()))
    payment = await payment_service.handle_atmos_callback(db, payload)
    return Message(message=f"OK: {payment.status}")


# ──────────────────────────────────────────────
#  Admin: payment reporting  (mounted at /admin)
# ──────────────────────────────────────────────


@admin_router.get("/payments", response_model=Page[PaymentListItem])
async def list_payments(
    _: AdminUser,
    db: DbSession,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    provider: PaymentProvider | None = Query(None),
    status: str | None = Query(None),
) -> Page[PaymentListItem]:
    """List all payments with optional filtering (admin only)."""
    base = select(Payment)
    if provider:
        base = base.where(Payment.provider == provider)
    if status:
        try:
            ps = PaymentStatus(status)
            base = base.where(Payment.status == ps)
        except ValueError:
            raise AppError(f"Noto'g'ri status: {status}", status_code=400)

    total = (
        await db.execute(select(func.count()).select_from(base.subquery()))
    ).scalar_one()

    rows = (
        await db.execute(
            base.order_by(Payment.created_at.desc())
            .offset((page - 1) * size)
            .limit(size)
        )
    ).scalars().all()

    return Page[PaymentListItem](
        items=list(rows),
        total=total,
        page=page,
        size=size,
    )


@admin_router.get("/payments/{payment_id}", response_model=PaymentRead)
async def get_payment(
    payment_id: uuid.UUID,
    _: AdminUser,
    db: DbSession,
) -> Payment:
    """Retrieve a single payment by ID (admin only)."""
    payment = await db.get(Payment, payment_id)
    if payment is None:
        raise NotFoundError("To'lov topilmadi.")
    return payment
