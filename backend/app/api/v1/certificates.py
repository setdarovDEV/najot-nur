"""Certificate request flow: user submits, curator approves or rejects."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.api.deps import CurrentUser, CuratorUser, DbSession
from app.core.exceptions import AppError, NotFoundError
from app.models.certificate import Certificate
from app.models.certificate_request import CertificateRequest
from app.models.course import Course, Enrollment
from app.models.enums import CertificateRequestStatus, EnrollmentStatus, PushAudience
from app.models.notification import PushNotification, PushToken
from app.models.user import User
from app.schemas.common import Message
from app.services import certificate_service, fcm

router = APIRouter()
admin_router = APIRouter()


# ───────────── User endpoints ─────────────

class CertRequestCreate(BaseModel):
    course_id: uuid.UUID
    full_name: str = Field(..., min_length=2, max_length=200)


@router.post("/request", response_model=Message)
async def submit_certificate_request(
    payload: CertRequestCreate,
    user: CurrentUser,
    db: DbSession,
) -> Message:
    """User submits a certificate request for a completed course."""
    enrollment = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id,
                Enrollment.course_id == payload.course_id,
                Enrollment.status == EnrollmentStatus.completed,
            )
        )
    ).scalar_one_or_none()
    if enrollment is None:
        raise AppError("Bu kursni tugatmagansiz yoki kursga yozilmagansiz.", status_code=400)

    existing = (
        await db.execute(
            select(CertificateRequest).where(
                CertificateRequest.user_id == user.id,
                CertificateRequest.course_id == payload.course_id,
                CertificateRequest.status == CertificateRequestStatus.pending,
            )
        )
    ).scalar_one_or_none()
    if existing is not None:
        raise AppError("Bu kurs uchun sertifikat so'rovingiz allaqachon yuborilgan.", status_code=409)

    already_has = (
        await db.execute(
            select(Certificate).where(
                Certificate.user_id == user.id,
                Certificate.course_id == payload.course_id,
            )
        )
    ).scalar_one_or_none()
    if already_has is not None:
        raise AppError("Bu kurs uchun sertifikat allaqachon berilgan.", status_code=409)

    req = CertificateRequest(
        user_id=user.id,
        course_id=payload.course_id,
        full_name=payload.full_name,
    )
    db.add(req)
    await db.flush()
    return Message(message="Sertifikat so'rovingiz curator(ga) yuborildi.")


@router.get("/my-requests")
async def my_certificate_requests(user: CurrentUser, db: DbSession) -> list[dict]:
    """User sees their own certificate requests."""
    rows = (
        await db.execute(
            select(CertificateRequest, Course)
            .join(Course, CertificateRequest.course_id == Course.id)
            .where(CertificateRequest.user_id == user.id)
            .order_by(CertificateRequest.created_at.desc())
        )
    ).all()
    return [
        {
            "id": str(req.id),
            "course_id": str(course.id),
            "course_title": course.title,
            "full_name": req.full_name,
            "status": req.status.value,
            "rejection_reason": req.rejection_reason,
            "created_at": req.created_at.isoformat(),
            "reviewed_at": req.reviewed_at.isoformat() if req.reviewed_at else None,
        }
        for req, course in rows
    ]


# ───────────── Curator / Admin endpoints ─────────────

@admin_router.get("/certificate-requests")
async def list_certificate_requests(
    _: CuratorUser,
    db: DbSession,
    status: CertificateRequestStatus | None = None,
) -> list[dict]:
    """Curator sees all certificate requests with user info and course title."""
    stmt = (
        select(CertificateRequest, User, Course)
        .join(User, CertificateRequest.user_id == User.id)
        .join(Course, CertificateRequest.course_id == Course.id)
        .order_by(CertificateRequest.created_at.desc())
        .limit(200)
    )
    if status:
        stmt = stmt.where(CertificateRequest.status == status)
    rows = (await db.execute(stmt)).all()
    return [
        {
            "id": str(req.id),
            "user_id": str(req.user_id),
            "user_full_name": user.full_name,
            "user_phone": user.phone,
            "course_id": str(course.id),
            "course_title": course.title,
            "full_name": req.full_name,
            "status": req.status.value,
            "rejection_reason": req.rejection_reason,
            "created_at": req.created_at.isoformat(),
            "reviewed_at": req.reviewed_at.isoformat() if req.reviewed_at else None,
        }
        for req, user, course in rows
    ]


class RejectPayload(BaseModel):
    reason: str | None = Field(None, max_length=500)


@admin_router.post("/certificate-requests/{request_id}/approve", response_model=Message)
async def approve_certificate_request(
    request_id: uuid.UUID,
    curator: CuratorUser,
    db: DbSession,
) -> Message:
    """Curator approves: generates a PDF certificate and pushes a notification."""
    req = await db.get(CertificateRequest, request_id)
    if req is None:
        raise NotFoundError("So'rov topilmadi.")
    if req.status != CertificateRequestStatus.pending:
        raise AppError("Bu so'rov allaqachon ko'rib chiqilgan.", status_code=409)

    course = await db.get(Course, req.course_id)
    if course is None:
        raise NotFoundError("Kurs topilmadi.")

    serial = certificate_service.generate_serial()
    pdf_url = await certificate_service.build_certificate_pdf(
        full_name=req.full_name,
        course_title=course.title,
        serial=serial,
        grade=None,
    )

    cert = Certificate(
        user_id=req.user_id,
        course_id=req.course_id,
        serial_number=serial,
        pdf_url=pdf_url,
    )
    db.add(cert)

    req.status = CertificateRequestStatus.approved
    req.reviewed_by_id = curator.id
    req.reviewed_at = datetime.now(UTC)
    await db.flush()

    push_title = "Sertifikat tasdiqlandi!"
    push_body = f'"{course.title}" kursi uchun sertifikatingiz tayyor. Yuklab oling!'
    await _push_to_user(req.user_id, push_title, push_body, db)

    notif = PushNotification(
        title=push_title,
        body=push_body,
        audience=PushAudience.user,
        target_id=req.user_id,
        sent_by=curator.id,
        sent_at=datetime.now(UTC),
    )
    db.add(notif)
    return Message(message="Sertifikat tasdiqlandi va foydalanuvchiga push yuborildi.")


@admin_router.post("/certificate-requests/{request_id}/reject", response_model=Message)
async def reject_certificate_request(
    request_id: uuid.UUID,
    payload: RejectPayload,
    curator: CuratorUser,
    db: DbSession,
) -> Message:
    """Curator rejects the request and optionally provides a reason."""
    req = await db.get(CertificateRequest, request_id)
    if req is None:
        raise NotFoundError("So'rov topilmadi.")
    if req.status != CertificateRequestStatus.pending:
        raise AppError("Bu so'rov allaqachon ko'rib chiqilgan.", status_code=409)

    course = await db.get(Course, req.course_id)
    course_title = course.title if course else "kurs"

    req.status = CertificateRequestStatus.rejected
    req.rejection_reason = payload.reason
    req.reviewed_by_id = curator.id
    req.reviewed_at = datetime.now(UTC)

    push_title = "Sertifikat so'rovi rad etildi"
    push_body = (
        f'"{course_title}" kursi uchun sertifikat so\'rovingiz rad etildi.'
        + (f" Sabab: {payload.reason}" if payload.reason else "")
    )
    await _push_to_user(req.user_id, push_title, push_body, db)

    notif = PushNotification(
        title=push_title,
        body=push_body,
        audience=PushAudience.user,
        target_id=req.user_id,
        sent_by=curator.id,
        sent_at=datetime.now(UTC),
    )
    db.add(notif)
    return Message(message="So'rov rad etildi va foydalanuvchiga push yuborildi.")


async def _push_to_user(user_id: uuid.UUID, title: str, body: str, db: DbSession) -> None:
    tokens = (
        await db.execute(
            select(PushToken.token).where(PushToken.user_id == user_id)
        )
    ).scalars().all()
    if tokens:
        await fcm.send_to_tokens(tokens, title=title, body=body)
