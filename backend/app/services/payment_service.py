"""Payment orchestration service — Uzum Bank, Uzum Nasiya, ATMOS.

Real HTTP calls are made when API keys are present in settings.
In development (keys absent), a mock redirect URL is returned so the
rest of the flow (DB record, callbacks) can be exercised without live keys.
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import uuid
from datetime import UTC, datetime
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppError, NotFoundError
from app.core.logging import get_logger
from app.models.audiobook import Audiobook, AudiobookAccess
from app.models.course import Course, Enrollment, Lesson
from app.models.enums import (
    EnrollmentStatus,
    HomeworkStatus,
    PaymentProvider,
    PaymentPurpose,
    PaymentStatus,
    PushAudience,
)
from app.models.grading import Homework
from app.models.notification import PushNotification, PushToken
from app.models.payment import Payment
from app.services import fcm

log = get_logger("payment_service")

# ──────────────────────────────────────────────
#  Provider base URLs  (change to sandbox for testing)
# ──────────────────────────────────────────────

_UZUM_BASE = "https://api.paymart.uz"
_UZUM_NASIYA_BASE = "https://api.nasiya.uz"
_ATMOS_BASE = "https://partner.atmos.uz"

_HTTP_TIMEOUT = 20.0  # seconds


# ──────────────────────────────────────────────
#  Internal DB helpers
# ──────────────────────────────────────────────


async def _create_payment(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None,
    purpose: PaymentPurpose,
    provider: PaymentProvider,
) -> Payment:
    payment = Payment(
        user_id=user_id,
        amount=amount,
        currency="UZS",
        provider=provider,
        status=PaymentStatus.pending,
        purpose=purpose,
        reference_id=reference_id,
    )
    db.add(payment)
    await db.flush()
    return payment


async def _get_payment_by_external_id(db: AsyncSession, external_id: str) -> Payment:
    row = (
        await db.execute(
            select(Payment).where(Payment.external_id == external_id)
        )
    ).scalar_one_or_none()
    if row is None:
        raise NotFoundError(f"To'lov topilmadi: external_id={external_id}")
    return row


# ──────────────────────────────────────────────
#  Uzum Bank  (paymart.uz)
# ──────────────────────────────────────────────
#
#  Docs: https://developer.paymart.uz
#  Auth: Basic  (merchantId:secretKey → base64)
#  POST /v1/payment
#    body  → { orderId, amount (tiyin), returnUrl, failedUrl, currency }
#    resp  → { paymentId, paymentUrl }
# ──────────────────────────────────────────────


async def initiate_uzum(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
) -> tuple[Payment, str]:
    """Create a pending Payment record and initiate a Uzum Bank checkout.

    Returns (payment, redirect_url).
    """
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.uzum,
    )

    if settings.uzum_merchant_id and settings.uzum_secret_key:
        credentials = base64.b64encode(
            f"{settings.uzum_merchant_id}:{settings.uzum_secret_key}".encode()
        ).decode()

        try:
            async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
                resp = await client.post(
                    f"{_UZUM_BASE}/v1/payment",
                    headers={
                        "Authorization": f"Basic {credentials}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "orderId": str(payment.id),
                        "amount": int(amount * 100),   # tiyin
                        "currency": "UZS",
                        "returnUrl": return_url,
                        "failedUrl": return_url,
                        "merchantId": settings.uzum_merchant_id,
                    },
                )
                resp.raise_for_status()
                data: dict[str, Any] = resp.json()

            external_id = str(
                data.get("paymentId") or data.get("id") or payment.id
            )
            redirect_url: str = (
                data.get("paymentUrl") or data.get("url")
                or f"https://checkout.uzum.uz/pay/{external_id}"
            )
            payment.external_id = external_id
            log.info(
                "uzum.initiated",
                payment_id=str(payment.id),
                external_id=external_id,
                amount=amount,
            )

        except httpx.HTTPStatusError as exc:
            log.error(
                "uzum.api_error",
                status=exc.response.status_code,
                body=exc.response.text,
                payment_id=str(payment.id),
            )
            raise AppError(
                f"Uzum Bank xatoligi: {exc.response.status_code} — {exc.response.text}",
                status_code=502,
            ) from exc

        except httpx.RequestError as exc:
            log.error("uzum.network_error", error=str(exc), payment_id=str(payment.id))
            raise AppError("Uzum Bank bilan aloqa yo'q.", status_code=502) from exc

    else:
        # Development stub — no real API call
        mock_external_id = f"uzum_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.uzum.uz/pay?order_id={payment.id}"
        log.warning(
            "uzum.stub_mode",
            hint="UZUM_MERCHANT_ID va UZUM_SECRET_KEY o'rnatilmagan",
            payment_id=str(payment.id),
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="uzum",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
    )
    return payment, redirect_url


# ──────────────────────────────────────────────
#  Uzum Nasiya  (bo'lib-bo'lib to'lash)
# ──────────────────────────────────────────────
#
#  Docs: https://api.nasiya.uz/swagger
#  Auth: Bearer {uzum_nasiya_api_key}
#  POST /api/v2/partner/invoice
#    body  → { amount (tiyin), period (months), orderId, redirectUrl }
#    resp  → { data: { id, link } }
# ──────────────────────────────────────────────


async def initiate_uzum_nasiya(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
    months: int = 6,
) -> tuple[Payment, str]:
    """Create a pending Payment record and initiate a Uzum Nasiya installment.

    Returns (payment, redirect_url).
    """
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.uzum_nasiya,
    )

    if settings.uzum_nasiya_api_key:
        try:
            async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
                resp = await client.post(
                    f"{_UZUM_NASIYA_BASE}/api/v2/partner/invoice",
                    headers={
                        "Authorization": f"Bearer {settings.uzum_nasiya_api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "amount": int(amount * 100),   # tiyin
                        "period": months,
                        "orderId": str(payment.id),
                        "redirectUrl": return_url,
                    },
                )
                resp.raise_for_status()
                data: dict[str, Any] = resp.json()

            inner = data.get("data") or data
            external_id = str(
                inner.get("id") or inner.get("invoiceId") or payment.id
            )
            redirect_url: str = (
                inner.get("link") or inner.get("redirectUrl") or inner.get("url")
                or f"https://nasiya.uz/invoice/{external_id}"
            )
            payment.external_id = external_id
            log.info(
                "uzum_nasiya.initiated",
                payment_id=str(payment.id),
                external_id=external_id,
                amount=amount,
                months=months,
            )

        except httpx.HTTPStatusError as exc:
            log.error(
                "uzum_nasiya.api_error",
                status=exc.response.status_code,
                body=exc.response.text,
                payment_id=str(payment.id),
            )
            raise AppError(
                f"Uzum Nasiya xatoligi: {exc.response.status_code} — {exc.response.text}",
                status_code=502,
            ) from exc

        except httpx.RequestError as exc:
            log.error("uzum_nasiya.network_error", error=str(exc), payment_id=str(payment.id))
            raise AppError("Uzum Nasiya bilan aloqa yo'q.", status_code=502) from exc

    else:
        mock_external_id = f"nasiya_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.nasiya.uzum.uz/pay?order_id={payment.id}"
        log.warning(
            "uzum_nasiya.stub_mode",
            hint="UZUM_NASIYA_API_KEY o'rnatilmagan",
            payment_id=str(payment.id),
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="uzum_nasiya",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
    )
    return payment, redirect_url


# ──────────────────────────────────────────────
#  ATMOS  (oylik obuna / subscription)
# ──────────────────────────────────────────────
#
#  Docs: https://partner.atmos.uz/docs
#  Auth: OAuth2 client_credentials
#  Step 1 — GET token
#    POST /merchant/auth/token
#    body (form) → grant_type=client_credentials&consumer_key=…&consumer_secret=…
#    resp → { access_token, token_type, expires_in }
#  Step 2 — Create transaction
#    POST /merchant/pay/create
#    headers → Authorization: Bearer {token}
#    body  → { amount (tiyin), account (our orderId), store_id, lang }
#    resp  → { result: {code, description}, transaction_id, checkout_url }
# ──────────────────────────────────────────────


async def _atmos_get_token() -> str:
    """Fetch a short-lived ATMOS OAuth2 Bearer token."""
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        resp = await client.post(
            f"{_ATMOS_BASE}/merchant/auth/token",
            data={
                "grant_type": "client_credentials",
                "consumer_key": settings.atmos_consumer_key,
                "consumer_secret": settings.atmos_consumer_secret,
            },
        )
        resp.raise_for_status()
        return str(resp.json()["access_token"])


async def initiate_atmos(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
) -> tuple[Payment, str]:
    """Create a pending Payment record and initiate an ATMOS checkout.

    Returns (payment, redirect_url).
    """
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.atmos,
    )

    if settings.atmos_store_id and settings.atmos_consumer_key and settings.atmos_consumer_secret:
        try:
            token = await _atmos_get_token()

            async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
                resp = await client.post(
                    f"{_ATMOS_BASE}/merchant/pay/create",
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "amount": int(amount * 100),         # tiyin
                        "account": str(payment.id),          # our internal order id
                        "store_id": int(settings.atmos_store_id),
                        "lang": "ru",
                        "return_url": return_url,
                    },
                )
                resp.raise_for_status()
                data: dict[str, Any] = resp.json()

            result = data.get("result", {})
            code = str(result.get("code", "")) if isinstance(result, dict) else str(result)
            if code not in ("0", "200", "success", ""):
                raise AppError(
                    f"ATMOS xatoligi: {result}",
                    status_code=502,
                )

            external_id = str(
                data.get("transaction_id") or data.get("transactionId") or payment.id
            )
            redirect_url: str = (
                data.get("checkout_url") or data.get("checkoutUrl") or data.get("url")
                or f"{_ATMOS_BASE}/checkout/{external_id}"
            )
            payment.external_id = external_id
            log.info(
                "atmos.initiated",
                payment_id=str(payment.id),
                external_id=external_id,
                amount=amount,
            )

        except httpx.HTTPStatusError as exc:
            log.error(
                "atmos.api_error",
                status=exc.response.status_code,
                body=exc.response.text,
                payment_id=str(payment.id),
            )
            raise AppError(
                f"ATMOS xatoligi: {exc.response.status_code} — {exc.response.text}",
                status_code=502,
            ) from exc

        except httpx.RequestError as exc:
            log.error("atmos.network_error", error=str(exc), payment_id=str(payment.id))
            raise AppError("ATMOS bilan aloqa yo'q.", status_code=502) from exc

    else:
        mock_external_id = f"atmos_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.atmos.uz/pay?order_id={payment.id}"
        log.warning(
            "atmos.stub_mode",
            hint="ATMOS_STORE_ID, ATMOS_CONSUMER_KEY yoki ATMOS_CONSUMER_SECRET o'rnatilmagan",
            payment_id=str(payment.id),
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="atmos",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
    )
    return payment, redirect_url


# ──────────────────────────────────────────────
#  Access-grant + homework helpers
# ──────────────────────────────────────────────


async def _ensure_homework_for_enrollment(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    course_id: uuid.UUID,
) -> int:
    lesson_ids = (
        await db.execute(
            select(Lesson.id).where(Lesson.course_id == course_id)
        )
    ).scalars().all()
    if not lesson_ids:
        return 0

    existing_lesson_ids = set(
        (
            await db.execute(
                select(Homework.lesson_id).where(
                    Homework.user_id == user_id,
                    Homework.lesson_id.in_(lesson_ids),
                )
            )
        ).scalars().all()
    )

    created = 0
    for lid in lesson_ids:
        if lid in existing_lesson_ids:
            continue
        db.add(
            Homework(
                user_id=user_id,
                lesson_id=lid,
                status=HomeworkStatus.submitted,
            )
        )
        created += 1
    return created


async def _grant_access_for_payment(db: AsyncSession, payment: Payment) -> None:
    if payment.reference_id is None or payment.purpose is None:
        log.warning(
            "payment.grant_skipped",
            payment_id=str(payment.id),
            reason="missing reference_id or purpose",
        )
        return

    if payment.purpose == PaymentPurpose.course:
        existing = (
            await db.execute(
                select(Enrollment).where(
                    Enrollment.user_id == payment.user_id,
                    Enrollment.course_id == payment.reference_id,
                )
            )
        ).scalar_one_or_none()
        if existing:
            existing.status = EnrollmentStatus.active
        else:
            db.add(
                Enrollment(
                    user_id=payment.user_id,
                    course_id=payment.reference_id,
                    status=EnrollmentStatus.active,
                )
            )
        await _ensure_homework_for_enrollment(
            db,
            user_id=payment.user_id,
            course_id=payment.reference_id,
        )
    elif payment.purpose == PaymentPurpose.audiobook:
        stmt = (
            pg_insert(AudiobookAccess)
            .values(user_id=payment.user_id, audiobook_id=payment.reference_id)
            .on_conflict_do_nothing(constraint="user_audiobook_access")
        )
        await db.execute(stmt)


async def _notify_payment_success(db: AsyncSession, payment: Payment) -> None:
    title = "To'lov tasdiqlandi ✅"
    if payment.purpose == PaymentPurpose.course and payment.reference_id:
        course = await db.get(Course, payment.reference_id)
        body = (
            f'"{course.title if course else "kurs"}" uchun to\'lovingiz muvaffaqiyatli '
            f"amalga oshirildi. Kurs ochildi — o'rganishni boshlashingiz mumkin!"
        )
    elif payment.purpose == PaymentPurpose.audiobook and payment.reference_id:
        book = await db.get(Audiobook, payment.reference_id)
        body = (
            f'"{book.title if book else "audiokitob"}" uchun to\'lovingiz muvaffaqiyatli '
            f"amalga oshirildi. Audiokitob ochildi — tinglashni boshlashingiz mumkin!"
        )
    else:
        body = "To'lovingiz muvaffaqiyatli amalga oshirildi."

    try:
        tokens = (
            await db.execute(
                select(PushToken.token).where(PushToken.user_id == payment.user_id)
            )
        ).scalars().all()
        delivered_count = 0
        if tokens:
            fcm_result = await fcm.send_to_tokens(
                tokens,
                title=title,
                body=body,
                data={"kind": "order_status", "payment_id": str(payment.id)},
            )
            delivered_count = (
                fcm_result["success"]
                if (fcm_result["success"] or fcm_result["failure"])
                else len(tokens)
            )
        db.add(
            PushNotification(
                title=title,
                body=body,
                audience=PushAudience.user,
                target_id=payment.user_id,
                sent_at=datetime.now(UTC),
                delivered_count=delivered_count,
            )
        )
    except Exception as exc:  # noqa: BLE001
        log.error("payment.notify_failed", payment_id=str(payment.id), error=str(exc))


# ──────────────────────────────────────────────
#  Webhook / callback handlers
# ──────────────────────────────────────────────


def _verify_uzum_signature(payload: dict[str, Any]) -> bool:
    if not settings.uzum_secret_key:
        log.warning("uzum.signature_check_skipped", reason="no secret configured")
        return True
    received_sig = payload.get("signature", "")
    order_id = payload.get("order_id", "")
    amount = payload.get("amount", 0)
    expected = hmac.new(
        settings.uzum_secret_key.encode(),
        f"{order_id}:{amount}".encode(),
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(received_sig, expected)


async def handle_uzum_callback(db: AsyncSession, payload: dict[str, Any]) -> Payment:
    log.info("uzum.callback_received", payload_keys=list(payload.keys()))

    if not _verify_uzum_signature(payload):
        raise AppError("Uzum webhook imzosi yaroqsiz.", status_code=400)

    external_id = str(payload.get("transaction_id") or payload.get("order_id") or payload.get("paymentId") or "")
    if not external_id:
        raise AppError("Uzum callback: order_id yoki transaction_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    uzum_status = str(payload.get("status", "")).lower()
    if uzum_status in ("paid", "confirmed", "success", "succeeded"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("uzum.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif uzum_status in ("failed", "cancelled", "declined", "expired"):
        payment.status = PaymentStatus.failed
        log.info("uzum.payment_failed", payment_id=str(payment.id), status=uzum_status)
    else:
        log.warning("uzum.unknown_status", status=uzum_status, payment_id=str(payment.id))

    await db.flush()
    return payment


async def handle_uzum_nasiya_callback(db: AsyncSession, payload: dict[str, Any]) -> Payment:
    log.info("uzum_nasiya.callback_received", payload_keys=list(payload.keys()))

    external_id = str(payload.get("order_id") or payload.get("installment_id") or payload.get("id") or "")
    if not external_id:
        raise AppError("Uzum Nasiya callback: order_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    nasiya_status = str(payload.get("status", "")).lower()
    if nasiya_status in ("approved", "paid", "active", "success"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("uzum_nasiya.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif nasiya_status in ("rejected", "cancelled", "failed", "expired"):
        payment.status = PaymentStatus.failed
        log.info("uzum_nasiya.payment_failed", payment_id=str(payment.id), status=nasiya_status)
    else:
        log.warning("uzum_nasiya.unknown_status", status=nasiya_status, payment_id=str(payment.id))

    await db.flush()
    return payment


def _verify_atmos_signature(payload: dict[str, Any]) -> bool:
    if not settings.atmos_consumer_secret:
        log.warning("atmos.signature_check_skipped", reason="no secret configured")
        return True
    received_sig = payload.get("sign", "")
    transaction_id = payload.get("transaction_id", "")
    amount = payload.get("amount", 0)
    store_id = settings.atmos_store_id
    raw = f"{store_id}{transaction_id}{amount}"
    expected = hmac.new(
        settings.atmos_consumer_secret.encode(), raw.encode(), hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(received_sig, expected)


async def handle_atmos_callback(db: AsyncSession, payload: dict[str, Any]) -> Payment:
    log.info("atmos.callback_received", payload_keys=list(payload.keys()))

    if not _verify_atmos_signature(payload):
        raise AppError("ATMOS webhook imzosi yaroqsiz.", status_code=400)

    external_id = str(payload.get("transaction_id") or payload.get("transactionId") or payload.get("order_id") or "")
    if not external_id:
        raise AppError("ATMOS callback: transaction_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    atmos_result = payload.get("result", {})
    code = str(atmos_result.get("code", "")) if isinstance(atmos_result, dict) else str(atmos_result)

    if code in ("0", "200", "success"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("atmos.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif code in ("1", "failed", "cancelled", "expired"):
        payment.status = PaymentStatus.failed
        log.info("atmos.payment_failed", payment_id=str(payment.id), code=code)
    else:
        log.warning("atmos.unknown_status", code=code, payment_id=str(payment.id))

    await db.flush()
    return payment
