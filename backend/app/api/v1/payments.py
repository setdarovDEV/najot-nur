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
    NasiyaCalculateRequest,
    NasiyaCalculateResponse,
    NasiyaCalculatedTariff,
    NasiyaCheckStatusRequest,
    NasiyaCheckStatusResponse,
    NasiyaPaymentActionRequest,
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
        if not payload.period:
            raise AppError(
                "Uzum Nasiya uchun 'period' talab qilinadi "
                "(POST /payments/uzum-nasiya/calculate orqali tanlang).",
                status_code=400,
            )
        payment, redirect_url = await payment_service.initiate_uzum_nasiya(
            db,
            user_id=current_user.id,
            amount=amount,
            reference_id=payload.reference_id,
            purpose=payload.purpose,
            return_url=payload.return_url,
            period=payload.period,
            product_name=payload.product_name or "Kurs",
            pinfl=payload.pinfl,
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
#  Uzum Nasiya — buyer status, tariff calc, and contract confirm/cancel.
#  (This API has no server-to-server webhook; the mobile app drives
#  confirm/cancel itself after the WebView OTP step completes.)
# ──────────────────────────────────────────────


@router.post("/uzum-nasiya/check-status", response_model=NasiyaCheckStatusResponse)
async def uzum_nasiya_check_status(
    payload: NasiyaCheckStatusRequest,
    current_user: CurrentUser,
) -> NasiyaCheckStatusResponse:
    """Check whether the buyer is registered/verified with Uzum Nasiya.

    If not, `webview` is a URL the app should open so the buyer can finish
    Uzum's own registration before a contract can be created.
    """
    phone = payload.phone or current_user.phone
    if not phone:
        raise AppError("Telefon raqami topilmadi.", status_code=400)
    data = await payment_service.uzum_nasiya_check_status(phone)
    return NasiyaCheckStatusResponse(**data)


@router.post("/uzum-nasiya/calculate", response_model=NasiyaCalculateResponse)
async def uzum_nasiya_calculate(
    payload: NasiyaCalculateRequest,
    current_user: CurrentUser,
) -> NasiyaCalculateResponse:
    """Return available installment tariffs (period/monthly payment) for an item."""
    if not current_user.phone:
        raise AppError("Telefon raqami topilmadi.", status_code=400)
    status_data = await payment_service.uzum_nasiya_check_status(current_user.phone)
    buyer_id = status_data.get("buyer_id")
    if status_data.get("status") != 4 or not buyer_id:
        raise AppError(
            "Uzum Nasiya: avval ro'yxatdan o'ting (check-status javobidagi webview).",
            status_code=400,
        )
    tariffs = await payment_service.uzum_nasiya_calculate(
        buyer_id=buyer_id, amount=float(payload.amount), reference_id=payload.reference_id
    )
    return NasiyaCalculateResponse(
        tariffs=[NasiyaCalculatedTariff(**t) for t in tariffs]
    )


@router.post("/uzum-nasiya/confirm", response_model=PaymentRead)
async def uzum_nasiya_confirm(
    payload: NasiyaPaymentActionRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> Payment:
    """Activate the contract after the buyer confirms OTP in the WebView.

    Called by the mobile app once it sees the WebView navigate back to the
    `return_url` it was given at /payments/initiate.
    """
    payment = await db.get(Payment, payload.payment_id)
    if payment is None or payment.user_id != current_user.id:
        raise NotFoundError("To'lov topilmadi.")
    return await payment_service.uzum_nasiya_confirm(db, payment_id=payload.payment_id)


@router.post("/uzum-nasiya/cancel", response_model=PaymentRead)
async def uzum_nasiya_cancel(
    payload: NasiyaPaymentActionRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> Payment:
    """Cancel a not-yet-activated Uzum Nasiya contract."""
    payment = await db.get(Payment, payload.payment_id)
    if payment is None or payment.user_id != current_user.id:
        raise NotFoundError("To'lov topilmadi.")
    return await payment_service.uzum_nasiya_cancel(db, payment_id=payload.payment_id)


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
