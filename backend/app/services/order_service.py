"""Order service — create zayavka, admin approve/reject.

Supports both courses and audiobooks. On approval, the user is granted
access: an `Enrollment` row for a course, or an `AudiobookAccess` row
for a audiobook. For courses, a placeholder `Homework` row is also
created for every lesson (the "uyga vazifa berish" flow).
"""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError, NotFoundError
from app.core.logging import get_logger
from app.models.audiobook import Audiobook, AudiobookAccess
from app.models.course import Course, Enrollment, Lesson
from app.models.enums import (
    EnrollmentStatus,
    HomeworkStatus,
    OrderPaymentMethod,
    OrderPurpose,
    OrderStatus,
    PushAudience,
)
from app.models.grading import Homework
from app.models.notification import PushNotification, PushToken
from app.models.order import Order
from app.services import fcm

log = get_logger("order_service")


async def create_order(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    purpose: OrderPurpose,
    course_id: uuid.UUID | None,
    audiobook_id: uuid.UUID | None,
    amount: float,
    payment_method: OrderPaymentMethod,
    payment_proof_url: str | None,
) -> Order:
    # ── Validate the target exists and is published ──
    if purpose == OrderPurpose.course:
        assert course_id is not None
        course = await db.get(Course, course_id)
        if course is None or not course.is_published:
            raise NotFoundError("Kurs topilmadi.")
    else:
        assert audiobook_id is not None
        book = await db.get(Audiobook, audiobook_id)
        if book is None or not book.is_published:
            raise NotFoundError("Audiokitob topilmadi.")

    # ── Block if user already has access ──
    if purpose == OrderPurpose.course:
        existing_enrollment = (
            await db.execute(
                select(Enrollment).where(
                    Enrollment.user_id == user_id,
                    Enrollment.course_id == course_id,
                    Enrollment.status == EnrollmentStatus.active,
                )
            )
        ).scalar_one_or_none()
        if existing_enrollment:
            raise AppError("Siz bu kursga allaqachon yozilgansiz.", status_code=409)
    else:
        existing_access = (
            await db.execute(
                select(AudiobookAccess).where(
                    AudiobookAccess.user_id == user_id,
                    AudiobookAccess.audiobook_id == audiobook_id,
                )
            )
        ).scalar_one_or_none()
        if existing_access:
            raise AppError(
                "Siz bu audiokitobga allaqachon kirish huquqiga egasiz.",
                status_code=409,
            )

    # ── Block duplicate pending zayavka for the same target ──
    target_filter = (
        (Order.course_id == course_id)
        if purpose == OrderPurpose.course
        else (Order.audiobook_id == audiobook_id)
    )
    existing_order = (
        await db.execute(
            select(Order).where(
                Order.user_id == user_id,
                Order.status == OrderStatus.pending,
                target_filter,
            )
        )
    ).scalar_one_or_none()
    if existing_order:
        raise AppError(
            "Bu kurs/audiokitob uchun tasdiqlash kutilayotgan zayavka mavjud.",
            status_code=409,
        )

    order = Order(
        user_id=user_id,
        purpose=purpose,
        course_id=course_id if purpose == OrderPurpose.course else None,
        audiobook_id=audiobook_id if purpose == OrderPurpose.audiobook else None,
        amount=amount,
        currency="UZS",
        payment_method=payment_method,
        status=OrderStatus.pending,
        payment_proof_url=payment_proof_url,
    )
    db.add(order)
    await db.flush()
    log.info(
        "order.created",
        order_id=str(order.id),
        user_id=str(user_id),
        purpose=purpose.value,
    )
    return order


async def approve_order(
    db: AsyncSession,
    *,
    order_id: uuid.UUID,
    admin_id: uuid.UUID,
    admin_note: str | None,
) -> Order:
    order = await db.get(Order, order_id)
    if order is None:
        raise NotFoundError("Zayavka topilmadi.")
    if order.status != OrderStatus.pending:
        raise AppError(
            f"Faqat 'pending' zayavkani tasdiqlash mumkin. Hozirgi holat: {order.status}",
            status_code=409,
        )

    order.status = OrderStatus.approved
    order.admin_note = admin_note
    order.reviewed_at = datetime.now(UTC)
    order.reviewed_by = admin_id

    if order.purpose == OrderPurpose.course:
        await grant_course_access(
            db, user_id=order.user_id, course_id=order.course_id  # type: ignore[arg-type]
        )
    else:
        # Idempotent: insert audiobook_access (unique on user+audiobook)
        stmt = (
            pg_insert(AudiobookAccess)
            .values(user_id=order.user_id, audiobook_id=order.audiobook_id)
            .on_conflict_do_nothing(constraint="user_audiobook_access")
        )
        await db.execute(stmt)

    await db.flush()

    # Notify the user via FCM + in-app feed. Wrapped in try/except so that
    # a transient push failure can never roll back an already-granted access.
    try:
        target_title, target_kind = await _resolve_target_title(db, order)
        push_title = "To'lov tasdiqlandi ✅"
        push_body = (
            f'"{target_title}" {target_kind}i uchun to\'lovingiz tasdiqlandi. '
            f"Sizga ochildi — o'rganishni boshlashingiz mumkin!"
        )
        await _notify_user(
            db,
            user_id=order.user_id,
            title=push_title,
            body=push_body,
            sent_by=admin_id,
            extra_data={
                "order_status": "approved",
                "course_id": str(order.course_id) if order.course_id else "",
                "audiobook_id": str(order.audiobook_id) if order.audiobook_id else "",
            },
        )
    except Exception as exc:  # noqa: BLE001
        log.error(
            "order.approve_notify_failed",
            order_id=str(order_id),
            error=str(exc),
        )

    log.info(
        "order.approved",
        order_id=str(order_id),
        admin_id=str(admin_id),
        purpose=order.purpose.value,
    )
    return order


async def reject_order(
    db: AsyncSession,
    *,
    order_id: uuid.UUID,
    admin_id: uuid.UUID,
    admin_note: str | None,
) -> Order:
    order = await db.get(Order, order_id)
    if order is None:
        raise NotFoundError("Zayavka topilmadi.")
    if order.status != OrderStatus.pending:
        raise AppError(
            f"Faqat 'pending' zayavkani rad etish mumkin. Hozirgi holat: {order.status}",
            status_code=409,
        )

    order.status = OrderStatus.rejected
    order.admin_note = admin_note
    order.reviewed_at = datetime.now(UTC)
    order.reviewed_by = admin_id

    await db.flush()

    # Same user-notification pattern as approve — never block the rejection
    # response on FCM availability.
    try:
        target_title, target_kind = await _resolve_target_title(db, order)
        push_title = "So'rov rad etildi ❌"
        reason_suffix = f" Sabab: {admin_note}" if admin_note else ""
        push_body = (
            f'"{target_title}" {target_kind}i uchun to\'lov so\'rovingiz '
            f"rad etildi.{reason_suffix}"
        )
        await _notify_user(
            db,
            user_id=order.user_id,
            title=push_title,
            body=push_body,
            sent_by=admin_id,
            extra_data={
                "order_status": "rejected",
                "course_id": str(order.course_id) if order.course_id else "",
                "audiobook_id": str(order.audiobook_id) if order.audiobook_id else "",
            },
        )
    except Exception as exc:  # noqa: BLE001
        log.error(
            "order.reject_notify_failed",
            order_id=str(order_id),
            error=str(exc),
        )

    log.info(
        "order.rejected",
        order_id=str(order_id),
        admin_id=str(admin_id),
        purpose=order.purpose.value,
    )
    return order


async def gift_course(
    db: AsyncSession,
    *,
    admin_id: uuid.UUID,
    user_id: uuid.UUID,
    course_id: uuid.UUID,
    admin_note: str | None,
) -> Order:
    """Grant a client free access to a course, bypassing payment.

    Recorded as an approved Order with payment_method=gift so the action
    stays visible/auditable in the same Orders history as paid purchases.
    """
    course = await db.get(Course, course_id)
    if course is None:
        raise NotFoundError("Kurs topilmadi.")

    order = Order(
        user_id=user_id,
        purpose=OrderPurpose.course,
        course_id=course_id,
        amount=0,
        currency="UZS",
        payment_method=OrderPaymentMethod.gift,
        status=OrderStatus.approved,
        admin_note=admin_note,
        reviewed_at=datetime.now(UTC),
        reviewed_by=admin_id,
    )
    db.add(order)
    await db.flush()

    await grant_course_access(db, user_id=user_id, course_id=course_id)
    await db.flush()

    try:
        await _notify_user(
            db,
            user_id=user_id,
            title="Sizga kurs sovg'a qilindi 🎁",
            body=f'"{course.title}" kursi sizga sovg\'a qilindi. O\'rganishni boshlashingiz mumkin!',
            sent_by=admin_id,
            extra_data={"order_status": "approved", "course_id": str(course_id)},
        )
    except Exception as exc:  # noqa: BLE001
        log.error("order.gift_notify_failed", course_id=str(course_id), error=str(exc))

    log.info(
        "order.gifted",
        order_id=str(order.id),
        admin_id=str(admin_id),
        user_id=str(user_id),
        course_id=str(course_id),
    )
    return order


async def grant_course_access(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    course_id: uuid.UUID,
) -> Enrollment:
    """Create/reactivate an Enrollment and auto-assign homework for every
    lesson in the course. Idempotent — safe to call more than once.
    """
    existing = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user_id,
                Enrollment.course_id == course_id,
            )
        )
    ).scalar_one_or_none()
    if existing:
        existing.status = EnrollmentStatus.active
        enrollment = existing
    else:
        enrollment = Enrollment(
            user_id=user_id,
            course_id=course_id,
            status=EnrollmentStatus.active,
        )
        db.add(enrollment)

    await _ensure_homework_for_enrollment(db, user_id=user_id, course_id=course_id)
    return enrollment


# ──────────────────────────────────────────────
#  Helpers
# ──────────────────────────────────────────────


async def _resolve_target_title(
    db: AsyncSession, order: Order
) -> tuple[str, str]:
    """Return (title, kind) where kind is "kurs" or "audiokitob"."""
    if order.purpose == OrderPurpose.course and order.course_id is not None:
        course = await db.get(Course, order.course_id)
        return (course.title if course else "kurs", "kurs")
    if order.purpose == OrderPurpose.audiobook and order.audiobook_id is not None:
        book = await db.get(Audiobook, order.audiobook_id)
        return (book.title if book else "audiokitob", "audiokitob")
    return ("buyum", "buyum")


async def _ensure_homework_for_enrollment(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    course_id: uuid.UUID,
) -> int:
    """Create a placeholder Homework row for every lesson in the course
    that the user does not yet have a row for. Idempotent.

    Returns the number of placeholder rows created.
    """
    lesson_ids = (
        await db.execute(select(Lesson.id).where(Lesson.course_id == course_id))
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


async def _notify_user(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    title: str,
    body: str,
    sent_by: uuid.UUID,
    extra_data: dict | None = None,
) -> None:
    """Send FCM push to the user's device tokens and write an in-app
    PushNotification row so the message also appears in /users/me/notifications.
    """
    tokens = (
        await db.execute(
            select(PushToken.token).where(PushToken.user_id == user_id)
        )
    ).scalars().all()
    delivered_count = 0
    if tokens:
        fcm_result = await fcm.send_to_tokens(
            tokens,
            title=title,
            body=body,
            data={"kind": "order_status", **(extra_data or {})},
        )
        delivered_count = (
            fcm_result["success"]
            if (fcm_result["success"] or fcm_result["failure"])
            else len(tokens)
        )
    notif = PushNotification(
        title=title,
        body=body,
        audience=PushAudience.user,
        target_id=user_id,
        sent_by=sent_by,
        sent_at=datetime.now(UTC),
        delivered_count=delivered_count,
    )
    db.add(notif)
    await db.flush()
