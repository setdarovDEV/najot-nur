"""Certificate request flow: user submits, curator approves or rejects."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.deps import CurrentUser, CuratorUser, DbSession
from app.core.exceptions import AppError, NotFoundError
from app.models.analysis import SpeechAnalysis, VoiceAnalysis
from app.models.audiobook import AudiobookProgress, Audiobook
from app.models.certificate import Certificate
from app.models.certificate_request import CertificateRequest
from app.models.course import Course, Enrollment, LessonProgress
from app.models.enums import CertificateRequestStatus, EnrollmentStatus, PushAudience
from app.models.notification import PushNotification, PushToken
from app.models.practicum import Practicum
from app.models.practicum_submission import PracticumSubmission
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


@admin_router.get("/certificate-requests/{request_id}/student-stats")
async def certificate_request_student_stats(
    request_id: uuid.UUID,
    _: CuratorUser,
    db: DbSession,
) -> dict:
    """Full learning stats for the student who submitted this certificate request."""
    req = await db.get(CertificateRequest, request_id)
    if req is None:
        raise NotFoundError("So'rov topilmadi.")

    user_id = req.user_id
    course_id = req.course_id

    # ── 1. Kurs progress ────────────────────────────────────────────────
    enrollment = (
        await db.execute(
            select(Enrollment)
            .options(selectinload(Enrollment.lesson_progress))
            .where(Enrollment.user_id == user_id, Enrollment.course_id == course_id)
        )
    ).scalar_one_or_none()

    course = await db.get(Course, course_id)

    course_stats: dict = {}
    if enrollment and course:
        lp_map = {lp.lesson_id: lp for lp in enrollment.lesson_progress}
        from app.models.course import Lesson  # local import to avoid circular
        lessons_q = await db.execute(
            select(Lesson).where(Lesson.course_id == course_id).order_by(Lesson.order_index)
        )
        lessons = lessons_q.scalars().all()
        lesson_rows = []
        for ls in lessons:
            lp = lp_map.get(ls.id)
            lesson_rows.append({
                "title": ls.title,
                "order_index": ls.order_index,
                "completed": lp.is_completed if lp else False,
                "quiz_score": lp.auto_score if lp else None,
            })
        completed_count = sum(1 for r in lesson_rows if r["completed"])
        course_stats = {
            "lessons_total": len(lessons),
            "lessons_completed": completed_count,
            "progress_pct": enrollment.progress_pct,
            "status": enrollment.status.value,
            "lessons": lesson_rows,
        }

    # ── 2. Audiokitoblar ────────────────────────────────────────────────
    ab_rows = (
        await db.execute(
            select(AudiobookProgress, Audiobook)
            .join(Audiobook, AudiobookProgress.audiobook_id == Audiobook.id)
            .where(AudiobookProgress.user_id == user_id)
            .order_by(AudiobookProgress.last_listened_at.desc())
        )
    ).all()
    audiobooks_stats = [
        {
            "title": ab.title,
            "author": ab.author,
            "current_page": prog.current_page,
            "total_pages": ab.total_pages,
            "last_listened_at": prog.last_listened_at.isoformat(),
        }
        for prog, ab in ab_rows
    ]

    # ── 3. Praktikum natijalari ────────────────────────────────────────
    prac_rows = (
        await db.execute(
            select(PracticumSubmission, Practicum)
            .join(Practicum, PracticumSubmission.practicum_id == Practicum.id)
            .where(PracticumSubmission.user_id == user_id)
            .order_by(PracticumSubmission.created_at.desc())
        )
    ).all()
    practicum_stats = [
        {
            "title": prac.title,
            "score": sub.overall_score,
            "status": sub.status,
            "submitted_at": sub.created_at.isoformat(),
        }
        for sub, prac in prac_rows
    ]

    # ── 4. Nutq tahlili natijalari (so'nggi 10 ta) ───────────────────
    speech_rows = (
        await db.execute(
            select(SpeechAnalysis)
            .where(SpeechAnalysis.user_id == user_id)
            .order_by(SpeechAnalysis.created_at.desc())
            .limit(10)
        )
    ).scalars().all()
    speech_stats = [
        {
            "overall_score": s.overall_score,
            "meaning_score": s.meaning_score,
            "fluency_score": s.fluency_score,
            "summary": s.summary,
            "created_at": s.created_at.isoformat(),
        }
        for s in speech_rows
    ]

    return {
        "course": course_stats,
        "audiobooks": audiobooks_stats,
        "practicums": practicum_stats,
        "speech_analyses": speech_stats,
    }


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
