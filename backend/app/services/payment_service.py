"""Payment orchestration service.

All HTTP calls to actual payment providers (Uzum, Uzum Nasiya, ATMOS) are
stubbed out for development — they log the intent and return a mock response.
Wire up real HTTP clients (httpx) when API keys are available in production.
"""
from __future__ import annotations

import hashlib
import hmac
import uuid
from datetime import UTC, datetime
from typing import Any

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
#  Internal helpers
# ──────────────────────────────────────────────


def _uzum_signature(merchant_id: str, secret_key: str, amount: float, reference_id: str) -> str:
    """Compute an HMAC-SHA256 signature for Uzum requests (stub logic)."""
    payload = f"{merchant_id}:{amount:.2f}:{reference_id}"
    return hmac.new(secret_key.encode(), payload.encode(), hashlib.sha256).hexdigest()


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
    from sqlalchemy import select

    row = (
        await db.execute(
            select(Payment).where(Payment.external_id == external_id)
        )
    ).scalar_one_or_none()
    if row is None:
        raise NotFoundError(f"To'lov topilmadi: external_id={external_id}")
    return row


# ──────────────────────────────────────────────
#  Uzum one-time payment
# ──────────────────────────────────────────────


async def initiate_uzum(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
) -> Payment:
    """Create a pending Payment record and return a Uzum redirect URL (stubbed)."""
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.uzum,
    )

    if settings.uzum_merchant_id and settings.uzum_secret_key:
        # TODO: replace with real httpx call to Uzum Payment API
        log.info(
            "uzum.initiate_real",
            payment_id=str(payment.id),
            amount=amount,
        )
        redirect_url = f"https://checkout.uzum.uz/pay?merchant_id={settings.uzum_merchant_id}&order_id={payment.id}&amount={int(amount * 100)}&return_url={return_url}"
    else:
        # Development stub
        mock_external_id = f"uzum_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.uzum.uz/pay?order_id={payment.id}"
        log.info(
            "uzum.initiate_stub",
            payment_id=str(payment.id),
            amount=amount,
            mock_external_id=mock_external_id,
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="uzum",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
        redirect_url=redirect_url,
    )
    # Store redirect_url on the model via external_id field as a temporary measure;
    # the caller reads payment.id and constructs its own redirect_url.
    return payment


# ──────────────────────────────────────────────
#  Uzum Nasiya (installment) payment
# ──────────────────────────────────────────────


async def initiate_uzum_nasiya(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
) -> Payment:
    """Create a pending Payment record and return a Uzum Nasiya redirect URL (stubbed)."""
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.uzum_nasiya,
    )

    if settings.uzum_nasiya_api_key:
        # TODO: replace with real httpx call to Uzum Nasiya API
        log.info(
            "uzum_nasiya.initiate_real",
            payment_id=str(payment.id),
            amount=amount,
        )
        redirect_url = (
            f"https://nasiya.uzum.uz/installment?api_key={settings.uzum_nasiya_api_key}"
            f"&order_id={payment.id}&amount={int(amount * 100)}&return_url={return_url}"
        )
    else:
        mock_external_id = f"nasiya_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.nasiya.uzum.uz/pay?order_id={payment.id}"
        log.info(
            "uzum_nasiya.initiate_stub",
            payment_id=str(payment.id),
            amount=amount,
            mock_external_id=mock_external_id,
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="uzum_nasiya",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
        redirect_url=redirect_url,
    )
    return payment


# ──────────────────────────────────────────────
#  ATMOS subscription payment
# ──────────────────────────────────────────────


async def initiate_atmos(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
) -> Payment:
    """Create a pending Payment record and return an ATMOS checkout URL (stubbed)."""
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.atmos,
    )

    if settings.atmos_store_id and settings.atmos_consumer_key and settings.atmos_consumer_secret:
        # TODO: replace with real httpx call to ATMOS API (OAuth2 + create transaction)
        log.info(
            "atmos.initiate_real",
            payment_id=str(payment.id),
            amount=amount,
        )
        redirect_url = (
            f"https://checkout.atmos.uz/pay?store_id={settings.atmos_store_id}"
            f"&transaction_id={payment.id}&amount={int(amount * 100)}&return_url={return_url}"
        )
    else:
        mock_external_id = f"atmos_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.atmos.uz/pay?order_id={payment.id}"
        log.info(
            "atmos.initiate_stub",
            payment_id=str(payment.id),
            amount=amount,
            mock_external_id=mock_external_id,
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="atmos",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
        redirect_url=redirect_url,
    )
    return payment


# ──────────────────────────────────────────────
#  Access-grant + homework-assignment helpers
# ──────────────────────────────────────────────


async def _ensure_homework_for_enrollment(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    course_id: uuid.UUID,
) -> int:
    """Create a placeholder Homework row for every lesson in the course that
    the user does not yet have a submission for. Idempotent.

    Returns the number of placeholder rows created.
    """
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


async def _grant_access_for_payment(
    db: AsyncSession,
    payment: Payment,
) -> None:
    """Idempotently grant the user access to the course/audiobook that
    `payment` refers to and pre-create Homework placeholders.
    """
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
            .values(
                user_id=payment.user_id,
                audiobook_id=payment.reference_id,
            )
            .on_conflict_do_nothing(constraint="user_audiobook_access")
        )
        await db.execute(stmt)


async def _notify_payment_success(
    db: AsyncSession,
    payment: Payment,
) -> None:
    """Best-effort FCM + in-app push to the user announcing access granted."""
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
        if tokens:
            await fcm.send_to_tokens(
                tokens,
                title=title,
                body=body,
                data={"kind": "order_status", "payment_id": str(payment.id)},
            )
        db.add(
            PushNotification(
                title=title,
                body=body,
                audience=PushAudience.user,
                target_id=payment.user_id,
                sent_at=datetime.now(UTC),
            )
        )
    except Exception as exc:  # noqa: BLE001
        log.error(
            "payment.notify_failed",
            payment_id=str(payment.id),
            error=str(exc),
        )


# ──────────────────────────────────────────────
#  Callback handlers
# ──────────────────────────────────────────────


def _verify_uzum_signature(payload: dict[str, Any]) -> bool:
    """Verify Uzum webhook signature. Returns True in dev when no secret is set."""
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
    """Process a Uzum payment callback and update the Payment record."""
    log.info("uzum.callback_received", payload_keys=list(payload.keys()))

    if not _verify_uzum_signature(payload):
        raise AppError("Uzum webhook imzosi yaroqsiz.", status_code=400)

    # Uzum sends either `order_id` (our payment UUID) or `transaction_id`
    external_id = str(payload.get("transaction_id") or payload.get("order_id", ""))
    if not external_id:
        raise AppError("Uzum callback: order_id yoki transaction_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    uzum_status = payload.get("status", "").lower()
    if uzum_status in ("paid", "confirmed", "success"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("uzum.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif uzum_status in ("failed", "cancelled", "declined"):
        payment.status = PaymentStatus.failed
        log.info("uzum.payment_failed", payment_id=str(payment.id), uzum_status=uzum_status)
    else:
        log.warning("uzum.unknown_status", uzum_status=uzum_status, payment_id=str(payment.id))

    await db.flush()
    return payment


async def handle_uzum_nasiya_callback(db: AsyncSession, payload: dict[str, Any]) -> Payment:
    """Process a Uzum Nasiya webhook and update the Payment record."""
    log.info("uzum_nasiya.callback_received", payload_keys=list(payload.keys()))

    external_id = str(payload.get("order_id") or payload.get("installment_id", ""))
    if not external_id:
        raise AppError("Uzum Nasiya callback: order_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    nasiya_status = payload.get("status", "").lower()
    if nasiya_status in ("approved", "paid", "active"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("uzum_nasiya.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif nasiya_status in ("rejected", "cancelled", "failed"):
        payment.status = PaymentStatus.failed
        log.info(
            "uzum_nasiya.payment_failed",
            payment_id=str(payment.id),
            nasiya_status=nasiya_status,
        )
    else:
        log.warning(
            "uzum_nasiya.unknown_status",
            nasiya_status=nasiya_status,
            payment_id=str(payment.id),
        )

    await db.flush()
    return payment


def _verify_atmos_signature(payload: dict[str, Any]) -> bool:
    """Verify ATMOS webhook signature. Returns True in dev when no secret is set."""
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
    """Process an ATMOS payment callback and update the Payment record."""
    log.info("atmos.callback_received", payload_keys=list(payload.keys()))

    if not _verify_atmos_signature(payload):
        raise AppError("ATMOS webhook imzosi yaroqsiz.", status_code=400)

    external_id = str(payload.get("transaction_id") or payload.get("order_id", ""))
    if not external_id:
        raise AppError("ATMOS callback: transaction_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    atmos_status = payload.get("result", {})
    if isinstance(atmos_status, dict):
        code = str(atmos_status.get("code", ""))
    else:
        code = str(atmos_status)

    if code in ("0", "200", "success"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("atmos.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif code in ("1", "failed", "cancelled"):
        payment.status = PaymentStatus.failed
        log.info("atmos.payment_failed", payment_id=str(payment.id), code=code)
    else:
        log.warning("atmos.unknown_status", code=code, payment_id=str(payment.id))

    await db.flush()
    return payment
