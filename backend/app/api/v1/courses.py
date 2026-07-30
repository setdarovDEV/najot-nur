"""Courses, lessons, enrollment, post-lesson quizzes, certificate issuance."""
from __future__ import annotations

import hashlib
import hmac
import re
import time
import uuid

from fastapi import APIRouter, File, Response, UploadFile
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.api.deps import CurrentUser, DbSession, OptionalUser
from app.core.exceptions import (
    AppError,
    ConflictError,
    ForbiddenError,
    NotFoundError,
    UnauthorizedError,
)
from app.core.config import settings
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
from app.services import storage
from app.services.certificate_service import build_certificate_pdf, generate_serial

router = APIRouter()
log = get_logger("courses")

PASS_THRESHOLD = 60


def _hide_locked_video_urls(course: Course) -> CourseDetail:
    """Non-demo lessons' video_url must not leak via public course endpoints;
    the actual video is only served through the enrollment/demo-gated
    GET /lessons/{id} endpoint."""
    detail = CourseDetail.model_validate(course)
    for lesson in detail.lessons:
        if not lesson.is_demo:
            lesson.video_url = None
    return detail


@router.get("", response_model=list[CourseDetail])
async def list_courses(db: DbSession) -> list[CourseDetail]:
    rows = (
        await db.execute(
            select(Course)
            .where(Course.is_published.is_(True))
            .options(selectinload(Course.lessons))
            .order_by(Course.created_at)
        )
    ).scalars().all()
    return [_hide_locked_video_urls(course) for course in rows]


@router.get("/{course_id}", response_model=CourseDetail)
async def get_course(course_id: uuid.UUID, db: DbSession) -> CourseDetail:
    course = (
        await db.execute(
            select(Course)
            .where(Course.id == course_id)
            .options(selectinload(Course.lessons))
        )
    ).scalar_one_or_none()
    if course is None:
        raise NotFoundError("Kurs topilmadi.")
    return _hide_locked_video_urls(course)


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


@router.get("/me/enrollment-status")
async def my_enrollment_status(user: CurrentUser, db: DbSession) -> dict:
    """Foydalanuvchining kursga yozilganlik holati.

    Mobile ilova practicum/quiz/observation bo'limlarini ko'rsatishdan oldin
    shu endpoint orqali foydalanuvchining kamida bitta faol kursga ega
    ekanligini tekshiradi. Lock state shu asosida ko'rsatiladi.
    """
    if user.role in ("admin", "curator"):
        return {"has_active_enrollment": True, "is_staff": True}
    active = (
        await db.execute(
            select(Enrollment.id).where(
                Enrollment.user_id == user.id,
                Enrollment.status.in_([EnrollmentStatus.active, EnrollmentStatus.completed]),
            ).limit(1)
        )
    ).scalar_one_or_none()
    return {"has_active_enrollment": active is not None, "is_staff": False}


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
    course_id: uuid.UUID, user: OptionalUser, db: DbSession
) -> dict:
    """Returns enrollment + per-lesson completion for an enrolled user."""
    if user is None:
        return {"enrolled": False, "has_pending_order": False}

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
        "enrolled_at": enrollment.created_at.isoformat(),
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


async def _playback_url(stored: str | None) -> str | None:
    """Turn a stored media URL into something the client can actually fetch.

    The bucket is private, so object URLs are presigned. Local ``/media/...``
    paths are returned unchanged — nginx serves those directly in dev.
    """
    if not stored:
        return None
    key = storage.key_from_url(stored)
    if key is None:
        return stored
    return await storage.presign_get(key)


async def _authorize_lesson(
    lesson_id: uuid.UUID,
    user,
    db,
    *,
    load_questions: bool = False,
) -> tuple[Lesson, Enrollment | None]:
    """Load a lesson and enforce the demo/enrollment gate.

    Returns ``(lesson, enrollment)``; enrollment is None for demo lessons
    watched by anonymous or non-enrolled users.
    """
    stmt = select(Lesson).where(Lesson.id == lesson_id)
    if load_questions:
        stmt = stmt.options(selectinload(Lesson.questions))
    lesson = (await db.execute(stmt)).scalar_one_or_none()
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")

    enrollment = (
        await db.execute(
            select(Enrollment).where(
                Enrollment.user_id == user.id,
                Enrollment.course_id == lesson.course_id,
            )
        )
    ).scalar_one_or_none() if user else None
    if enrollment is None and not lesson.is_demo:
        if user is None:
            raise UnauthorizedError("Avtorizatsiya talab qilinadi.")
        raise ForbiddenError("Bu kursga yozilmagansiz.")
    return lesson, enrollment


@router.get("/lessons/{lesson_id}")
async def get_lesson(
    lesson_id: uuid.UUID, user: OptionalUser, db: DbSession
) -> dict:
    """Full lesson data including quiz questions (hidden correct_index).

    Demo lessons are viewable without enrollment, even by anonymous users.
    """
    lesson, enrollment = await _authorize_lesson(
        lesson_id, user, db, load_questions=True
    )

    progress = (
        await db.execute(
            select(LessonProgress).where(
                LessonProgress.enrollment_id == enrollment.id,
                LessonProgress.lesson_id == lesson_id,
            )
        )
    ).scalar_one_or_none() if enrollment else None

    return {
        "id": str(lesson.id),
        "title": lesson.title,
        "description": lesson.description,
        "video_url": await _playback_url(lesson.video_url),
        # Players should prefer the HLS master when it is ready; video_url is
        # the progressive-download fallback.
        # Tokenised: native players cannot attach our bearer header to the
        # segment requests, so the gate rides in the query string instead.
        "hls_url": (
            f"/api/v1/courses/lessons/{lesson.id}/hls/master.m3u8"
            f"?t={_playback_token(lesson.id)}"
            if lesson.hls_url
            else None
        ),
        "poster_url": await _playback_url(lesson.poster_url),
        "video_status": lesson.video_status,
        "duration_sec": lesson.duration_sec,
        "is_voice_exercise": lesson.is_voice_exercise,
        "voice_exercise_prompt": lesson.voice_exercise_prompt,
        "is_demo": lesson.is_demo,
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
    """Text and voice homework can be submitted together or independently.

    A student may send a text answer first and then attach a voice recording
    (or vice versa). Either field is optional but at least one must be set.
    """

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


@router.post("/lessons/{lesson_id}/homework/audio", response_model=dict)
async def upload_homework_audio(
    lesson_id: uuid.UUID,
    user: CurrentUser,
    db: DbSession,
    file: UploadFile = File(...),
) -> dict:
    """Upload a voice recording for homework and return a server URL.

    The mobile app calls this endpoint first to upload the audio file, then
    calls ``POST /lessons/{id}/homework`` with the returned ``audio_url`` in
    ``submission_url`` (optionally alongside text in ``submission_text``).
    """
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

    content_type = file.content_type or ""
    if not content_type.startswith("audio/"):
        raise AppError(
            "Faqat audio fayllari qabul qilinadi (audio/*).",
            status_code=400,
        )

    data = await file.read()
    if not data:
        raise AppError("Audio fayl bo'sh.", status_code=400)

    ext = (file.filename or "homework.m4a").rsplit(".", 1)[-1].lower()
    if ext not in {"m4a", "mp3", "aac", "wav", "ogg", "webm"}:
        ext = "m4a"

    url = await storage.save_bytes(
        data,
        folder="homework",
        filename=f"hw_{user.id}_{lesson_id}.{ext}",
        content_type=content_type or "audio/mp4",
    )
    log.info(
        "homework.audio_uploaded",
        user_id=str(user.id),
        lesson_id=str(lesson_id),
        url=url,
    )
    return {"audio_url": url}


@router.post("/lessons/{lesson_id}/homework", response_model=Message)
async def submit_homework(
    lesson_id: uuid.UUID,
    payload: HomeworkSubmit,
    user: CurrentUser,
    db: DbSession,
) -> Message:
    """Submit or resubmit homework for a lesson.

    A single Homework row per (user, lesson) can hold both text and voice.
    Sending text after a voice submission preserves the existing voice URL,
    and vice versa: only fields that are explicitly set in ``payload`` are
    updated. Empty strings are treated as ``None``.
    """
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

    new_text = (payload.submission_text or "").strip() or None
    new_url = (payload.submission_url or "").strip() or None

    if not new_text and not new_url:
        raise AppError("Matn yoki audio yuboring.", status_code=400)

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

    # Preserve existing text/url when the new payload does not provide them.
    if new_text is not None:
        hw.submission_text = new_text
    if new_url is not None:
        hw.submission_url = new_url

    hw.status = HomeworkStatus.submitted
    hw.curator_score = None
    hw.curator_feedback = None
    hw.reviewed_at = None
    await db.flush()
    log.info(
        "homework.submitted",
        user_id=str(user.id),
        lesson_id=str(lesson_id),
        has_text=bool(hw.submission_text),
        has_audio=bool(hw.submission_url),
    )
    return Message(message="Uy vazifasi yuborildi.")




# ─────────────────── HLS playback (enrollment-gated) ───────────────────
#
# The bucket is private, so segments cannot simply be linked: a player fetches
# them itself and carries no session. Instead the API serves the playlists —
# a few KB of text — with every segment URL individually presigned. The gate
# stays real (a non-enrolled user gets 403 at the playlist), while all the
# heavy bytes still come straight from the CDN edge, never from this process.
#
# Access is carried by a short-lived token in the query string rather than an
# Authorization header: segment URLs are SigV4-presigned, and S3/R2 reject a
# request that presents both query-string auth and an auth header. A native
# player applies its configured headers to every request in the stream, so a
# header-based scheme would break segment fetches.

_HLS_HEADERS = {
    # Playlists embed short-lived signatures; caching them past the signature
    # lifetime would hand players URLs that 403.
    "Cache-Control": "private, max-age=60",
}


def _playback_token(lesson_id: uuid.UUID) -> str:
    """Mint a ``<exp>.<sig>`` token authorising playback of one lesson.

    Stateless (HMAC over lesson + expiry) so no round-trip to Redis is needed
    on the segment path.
    """
    exp = int(time.time()) + settings.media_signed_url_ttl_sec
    sig = hmac.new(
        settings.jwt_secret_key.encode(),
        f"{lesson_id}.{exp}".encode(),
        hashlib.sha256,
    ).hexdigest()[:32]
    return f"{exp}.{sig}"


def _playback_token_valid(lesson_id: uuid.UUID, token: str | None) -> bool:
    if not token or "." not in token:
        return False
    exp_raw, _, sig = token.partition(".")
    try:
        exp = int(exp_raw)
    except ValueError:
        return False
    if exp < time.time():
        return False
    expected = hmac.new(
        settings.jwt_secret_key.encode(),
        f"{lesson_id}.{exp}".encode(),
        hashlib.sha256,
    ).hexdigest()[:32]
    return hmac.compare_digest(expected, sig)


async def _authorize_playback(
    lesson_id: uuid.UUID, token: str | None, user, db
) -> Lesson:
    """Allow playback via a valid token, else fall back to the session gate."""
    if _playback_token_valid(lesson_id, token):
        lesson = await db.get(Lesson, lesson_id)
        if lesson is None:
            raise NotFoundError("Dars topilmadi.")
        return lesson
    lesson, _ = await _authorize_lesson(lesson_id, user, db)
    return lesson


def _hls_prefix(lesson: Lesson) -> str:
    """Object-storage prefix holding the lesson's rendered HLS tree."""
    return f"videos/{lesson.id}/hls"


async def _load_playlist(key: str) -> str:
    raw = await storage.load_bytes(storage.object_url(key))
    if raw is None:
        raise NotFoundError("Video hali tayyor emas.")
    return raw.decode("utf-8", errors="replace")


@router.get("/lessons/{lesson_id}/hls/master.m3u8")
async def lesson_hls_master(
    lesson_id: uuid.UUID,
    user: OptionalUser,
    db: DbSession,
    t: str | None = None,
) -> Response:
    """Master playlist — variant URLs point back at this API, not the bucket."""
    lesson = await _authorize_playback(lesson_id, t, user, db)
    if not lesson.hls_url:
        raise NotFoundError("Video hali tayyor emas.")

    text = await _load_playlist(f"{_hls_prefix(lesson)}/master.m3u8")
    # The player fetches variant playlists on its own, so each must carry the
    # token forward — mint a fresh one rather than reusing a nearly-expired.
    token = _playback_token(lesson_id)
    base = f"/api/v1/courses/lessons/{lesson_id}/hls"
    out = []
    for line in text.splitlines():
        # Variant lines are the only non-comment entries in a master playlist.
        if line and not line.startswith("#"):
            out.append(f"{base}/{line.strip()}?t={token}")
        else:
            out.append(line)
    return Response(
        "\n".join(out),
        media_type="application/vnd.apple.mpegurl",
        headers=_HLS_HEADERS,
    )


@router.get("/lessons/{lesson_id}/hls/{rendition}/index.m3u8")
async def lesson_hls_variant(
    lesson_id: uuid.UUID,
    rendition: str,
    user: OptionalUser,
    db: DbSession,
    t: str | None = None,
) -> Response:
    """Variant playlist with each segment rewritten to a presigned CDN URL."""
    lesson = await _authorize_playback(lesson_id, t, user, db)
    if not lesson.hls_url:
        raise NotFoundError("Video hali tayyor emas.")
    # Renditions are named v0, v1, … by the transcoder — reject anything else
    # so this cannot be walked into another prefix.
    if not re.fullmatch(r"v\d{1,2}", rendition):
        raise NotFoundError("Sifat varianti topilmadi.")

    prefix = f"{_hls_prefix(lesson)}/{rendition}"
    text = await _load_playlist(f"{prefix}/index.m3u8")
    out = []
    for line in text.splitlines():
        if line and not line.startswith("#"):
            out.append(await storage.presign_get(f"{prefix}/{line.strip()}"))
        else:
            out.append(line)
    return Response(
        "\n".join(out),
        media_type="application/vnd.apple.mpegurl",
        headers=_HLS_HEADERS,
    )
