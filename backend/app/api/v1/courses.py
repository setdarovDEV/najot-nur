"""Courses, lessons, enrollment, post-lesson quizzes, certificate issuance."""
from __future__ import annotations

import uuid

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.api.deps import CurrentUser, DbSession
from app.core.exceptions import AppError, ConflictError, ForbiddenError, NotFoundError
from app.core.logging import get_logger
from app.models.certificate import Certificate
from app.models.course import (
    Course,
    Enrollment,
    Lesson,
    LessonProgress,
    LessonQuestion,
)
from app.models.enums import EnrollmentStatus, HomeworkStatus, OrderPurpose, OrderStatus
from app.models.order import Order
from app.models.grading import Homework
from app.schemas.common import Message
from app.schemas.course import (
    CourseDetail,
    CourseRead,
    EnrollmentRead,
    LessonRead,
    QuizResult,
    QuizSubmitRequest,
)
from app.services.certificate_service import build_certificate_pdf, generate_serial

router = APIRouter()
log = get_logger("courses")

PASS_THRESHOLD = 60


@router.get("", response_model=list[CourseDetail])
async def list_courses(db: DbSession) -> list[Course]:
    rows = (
        await db.execute(
            select(Course)
            .where(Course.is_published.is_(True))
            .options(selectinload(Course.lessons))
            .order_by(Course.created_at)
        )
    ).scalars().all()
    return list(rows)


@router.get("/{course_id}", response_model=CourseDetail)
async def get_course(course_id: uuid.UUID, db: DbSession) -> Course:
    course = (
        await db.execute(
            select(Course)
            .where(Course.id == course_id)
            .options(selectinload(Course.lessons))
        )
    ).scalar_one_or_none()
    if course is None:
        raise NotFoundError("Kurs topilmadi.")
    return course


@router.post("/{course_id}/enroll", response_model=EnrollmentRead)
async def enroll(course_id: uuid.UUID, user: CurrentUser, db: DbSession) -> Enrollment:
    course = await db.get(Course, course_id)
    if course is None:
        raise NotFoundError("Kurs topilmadi.")

    existing = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id, Enrollment.course_id == course_id
            )
        )
    ).scalar_one_or_none()
    if existing is not None:
        raise ConflictError("Siz allaqachon ushbu kursga yozilgansiz.")

    # NOTE: in production this happens after a successful payment.
    enrollment = Enrollment(user_id=user.id, course_id=course_id)
    db.add(enrollment)
    await db.flush()
    return enrollment


@router.get("/me/enrollments", response_model=list[EnrollmentRead])
async def my_enrollments(user: CurrentUser, db: DbSession) -> list[Enrollment]:
    rows = (
        await db.execute(select(Enrollment).where(Enrollment.user_id == user.id))
    ).scalars().all()
    return list(rows)


@router.post("/lessons/{lesson_id}/quiz", response_model=QuizResult)
async def submit_quiz(
    lesson_id: uuid.UUID,
    payload: QuizSubmitRequest,
    user: CurrentUser,
    db: DbSession,
) -> QuizResult:
    lesson = (
        await db.execute(
            select(Lesson)
            .where(Lesson.id == lesson_id)
            .options(selectinload(Lesson.questions))
        )
    ).scalar_one_or_none()
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")

    enrollment = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id,
                Enrollment.course_id == lesson.course_id,
            )
        )
    ).scalar_one_or_none()
    if enrollment is None:
        raise ForbiddenError("Avval kursga yoziling.")

    questions: list[LessonQuestion] = lesson.questions
    total = len(questions) or 1
    correct = sum(
        1
        for q in questions
        if payload.answers.get(q.id) == q.correct_index
    )
    score = round(correct / total * 100)
    passed = score >= PASS_THRESHOLD

    # Upsert lesson progress
    progress = (
        await db.execute(
            select(LessonProgress).where(
                LessonProgress.enrollment_id == enrollment.id,
                LessonProgress.lesson_id == lesson_id,
            )
        )
    ).scalar_one_or_none()
    if progress is None:
        progress = LessonProgress(enrollment_id=enrollment.id, lesson_id=lesson_id)
        db.add(progress)
    progress.auto_score = score
    progress.is_completed = passed

    await db.flush()
    await _recompute_progress(db, enrollment, user)

    return QuizResult(score=score, correct=correct, total=len(questions), passed=passed)


async def _recompute_progress(
    db: DbSession, enrollment: Enrollment, user: CurrentUser
) -> None:
    total_lessons = (
        await db.execute(
            select(func.count(Lesson.id)).where(
                Lesson.course_id == enrollment.course_id
            )
        )
    ).scalar_one()
    completed = (
        await db.execute(
            select(func.count(LessonProgress.id)).where(
                LessonProgress.enrollment_id == enrollment.id,
                LessonProgress.is_completed.is_(True),
            )
        )
    ).scalar_one()

    enrollment.progress_pct = (
        round(completed / total_lessons * 100) if total_lessons else 0
    )
    if total_lessons and completed >= total_lessons:
        enrollment.status = EnrollmentStatus.completed
        await _issue_certificate(db, enrollment, user)


async def _issue_certificate(
    db: DbSession, enrollment: Enrollment, user: CurrentUser
) -> None:
    existing = (
        await db.execute(
            select(Certificate).where(
                Certificate.user_id == user.id,
                Certificate.course_id == enrollment.course_id,
            )
        )
    ).scalar_one_or_none()
    if existing is not None:
        return

    course = await db.get(Course, enrollment.course_id)
    avg = (
        await db.execute(
            select(func.avg(LessonProgress.auto_score)).where(
                LessonProgress.enrollment_id == enrollment.id
            )
        )
    ).scalar_one()
    grade = round(avg) if avg is not None else None
    serial = generate_serial()
    pdf_url: str | None = None
    try:
        pdf_url = await build_certificate_pdf(
            full_name=user.full_name or "Najot Nur o'quvchisi",
            course_title=course.title if course else "Kurs",
            serial=serial,
            grade=grade,
        )
    except Exception as exc:  # pragma: no cover
        log.error("certificate.generation_failed", error=str(exc))

    db.add(
        Certificate(
            user_id=user.id,
            course_id=enrollment.course_id,
            serial_number=serial,
            pdf_url=pdf_url,
            grade=grade,
        )
    )
    log.info("certificate.issued", user=str(user.id), serial=serial)


# ─────────────────── Enrollment progress ───────────────────

@router.get("/{course_id}/my-progress")
async def my_course_progress(
    course_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> dict:
    """Returns enrollment + per-lesson completion for an enrolled user."""
    enrollment = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id,
                Enrollment.course_id == course_id,
            )
        )
    ).scalar_one_or_none()
    if enrollment is None:
        pending_order = (
            await db.execute(
                select(Order).where(
                    Order.user_id == user.id,
                    Order.course_id == course_id,
                    Order.purpose == OrderPurpose.course,
                    Order.status == OrderStatus.pending,
                )
            )
        ).scalar_one_or_none()
        return {"enrolled": False, "has_pending_order": pending_order is not None}

    lessons = (
        await db.execute(
            select(Lesson)
            .where(Lesson.course_id == course_id)
            .order_by(Lesson.order_index)
        )
    ).scalars().all()

    progress_rows = (
        await db.execute(
            select(LessonProgress).where(
                LessonProgress.enrollment_id == enrollment.id
            )
        )
    ).scalars().all()
    progress_map = {p.lesson_id: p for p in progress_rows}

    return {
        "enrolled": True,
        "enrollment_id": str(enrollment.id),
        "status": enrollment.status.value,
        "progress_pct": enrollment.progress_pct,
        "lessons": [
            {
                "lesson_id": str(ls.id),
                "title": ls.title,
                "order_index": ls.order_index,
                "duration_sec": ls.duration_sec,
                "is_voice_exercise": ls.is_voice_exercise,
                "is_completed": progress_map[ls.id].is_completed
                if ls.id in progress_map
                else False,
                "auto_score": progress_map[ls.id].auto_score
                if ls.id in progress_map
                else None,
            }
            for ls in lessons
        ],
    }


# ─────────────────── Lesson detail (enrolled users) ───────────────────

@router.get("/lessons/{lesson_id}")
async def get_lesson(
    lesson_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> dict:
    """Full lesson data including quiz questions (hidden correct_index)."""
    lesson = (
        await db.execute(
            select(Lesson)
            .where(Lesson.id == lesson_id)
            .options(selectinload(Lesson.questions))
        )
    ).scalar_one_or_none()
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")

    enrollment = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id,
                Enrollment.course_id == lesson.course_id,
            )
        )
    ).scalar_one_or_none()
    if enrollment is None:
        raise ForbiddenError("Bu kursga yozilmagansiz.")

    progress = (
        await db.execute(
            select(LessonProgress).where(
                LessonProgress.enrollment_id == enrollment.id,
                LessonProgress.lesson_id == lesson_id,
            )
        )
    ).scalar_one_or_none()

    return {
        "id": str(lesson.id),
        "title": lesson.title,
        "description": lesson.description,
        "video_url": lesson.video_url,
        "duration_sec": lesson.duration_sec,
        "is_voice_exercise": lesson.is_voice_exercise,
        "voice_exercise_prompt": lesson.voice_exercise_prompt,
        "is_completed": progress.is_completed if progress else False,
        "auto_score": progress.auto_score if progress else None,
        "questions": [
            {
                "id": str(q.id),
                "question": q.question,
                "options": q.options,
                "order_index": q.order_index,
            }
            for q in sorted(lesson.questions, key=lambda q: q.order_index)
        ],
    }


# ─────────────────── Mark lesson viewed (no quiz) ───────────────────

@router.post("/lessons/{lesson_id}/complete", response_model=Message)
async def complete_lesson(
    lesson_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> Message:
    """Mark a lesson as completed (for lessons without quiz questions)."""
    lesson = await db.get(Lesson, lesson_id)
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")

    enrollment = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id,
                Enrollment.course_id == lesson.course_id,
            )
        )
    ).scalar_one_or_none()
    if enrollment is None:
        raise ForbiddenError("Bu kursga yozilmagansiz.")

    progress = (
        await db.execute(
            select(LessonProgress).where(
                LessonProgress.enrollment_id == enrollment.id,
                LessonProgress.lesson_id == lesson_id,
            )
        )
    ).scalar_one_or_none()
    if progress is None:
        progress = LessonProgress(enrollment_id=enrollment.id, lesson_id=lesson_id)
        db.add(progress)
    progress.is_completed = True
    await db.flush()
    await _recompute_progress(db, enrollment, user)
    return Message(message="Dars yakunlandi.")


# ─────────────────── Homework ───────────────────

class HomeworkSubmit(BaseModel):
    submission_text: str | None = None
    submission_url: str | None = None


@router.get("/lessons/{lesson_id}/my-homework")
async def my_homework(
    lesson_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> dict | None:
    """Returns the user's existing homework submission for this lesson."""
    hw = (
        await db.execute(
            select(Homework).where(
                Homework.user_id == user.id,
                Homework.lesson_id == lesson_id,
            )
        )
    ).scalar_one_or_none()
    if hw is None:
        return None
    return {
        "id": str(hw.id),
        "status": hw.status.value,
        "submission_text": hw.submission_text,
        "submission_url": hw.submission_url,
        "curator_score": hw.curator_score,
        "curator_feedback": hw.curator_feedback,
        "reviewed_at": hw.reviewed_at.isoformat() if hw.reviewed_at else None,
        "created_at": hw.created_at.isoformat(),
    }


@router.post("/lessons/{lesson_id}/homework", response_model=Message)
async def submit_homework(
    lesson_id: uuid.UUID,
    payload: HomeworkSubmit,
    user: CurrentUser,
    db: DbSession,
) -> Message:
    """Submit or resubmit homework for a lesson."""
    lesson = await db.get(Lesson, lesson_id)
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")

    enrollment = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id,
                Enrollment.course_id == lesson.course_id,
            )
        )
    ).scalar_one_or_none()
    if enrollment is None:
        raise ForbiddenError("Bu kursga yozilmagansiz.")

    if not payload.submission_text and not payload.submission_url:
        raise AppError("Matn yoki fayl URL kiriting.", status_code=400)

    hw = (
        await db.execute(
            select(Homework).where(
                Homework.user_id == user.id,
                Homework.lesson_id == lesson_id,
            )
        )
    ).scalar_one_or_none()
    if hw is None:
        hw = Homework(user_id=user.id, lesson_id=lesson_id)
        db.add(hw)

    hw.submission_text = payload.submission_text
    hw.submission_url = payload.submission_url
    hw.status = HomeworkStatus.submitted
    hw.curator_score = None
    hw.curator_feedback = None
    hw.reviewed_at = None
    return Message(message="Uy vazifasi yuborildi.")
