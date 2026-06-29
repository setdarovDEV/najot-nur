"""Quiz endpoints — curator creates, admin approves, users take on mobile."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, File, UploadFile
from sqlalchemy import select

from app.api.deps import AdminUser, CurrentUser, CuratorUser, DbSession
from app.core.config import settings
from app.core.exceptions import AppError, ForbiddenError, NotFoundError
from app.models.quiz import Quiz, QuizAttempt
from app.schemas.quiz import (
    QuizAttemptCreate,
    QuizAttemptRead,
    QuizCreate,
    QuizDetail,
    QuizRead,
)
from app.services import storage

router = APIRouter()


def _to_read(q: Quiz) -> QuizRead:
    return QuizRead(
        id=q.id,
        title=q.title,
        description=q.description,
        difficulty=q.difficulty,
        status=q.status,
        category=q.category,
        question_count=len(q.questions or []),
        created_at=q.created_at,
        cover_image_url=q.cover_image_url,
        video_url=q.video_url,
    )


# ─── Public / user endpoints ───

@router.get("", response_model=list[QuizRead])
async def list_quizzes(db: DbSession, user: CurrentUser) -> list[QuizRead]:
    rows = (
        await db.execute(
            select(Quiz)
            .where(Quiz.status == "approved")
            .order_by(Quiz.created_at.desc())
        )
    ).scalars().all()
    return [_to_read(q) for q in rows]


@router.get("/{quiz_id}", response_model=QuizDetail)
async def get_quiz(quiz_id: uuid.UUID, db: DbSession, user: CurrentUser) -> QuizDetail:
    q = await db.get(Quiz, quiz_id)
    if q is None or q.status != "approved":
        raise NotFoundError("Test topilmadi.")
    return QuizDetail(
        id=q.id,
        title=q.title,
        description=q.description,
        difficulty=q.difficulty,
        status=q.status,
        category=q.category,
        question_count=len(q.questions or []),
        created_at=q.created_at,
        cover_image_url=q.cover_image_url,
        video_url=q.video_url,
        questions=[
            {"question": item["question"], "options": item["options"]}
            for item in (q.questions or [])
        ],
    )


@router.post("/{quiz_id}/attempt", response_model=QuizAttemptRead)
async def submit_attempt(
    quiz_id: uuid.UUID,
    payload: QuizAttemptCreate,
    db: DbSession,
    user: CurrentUser,
) -> QuizAttempt:
    q = await db.get(Quiz, quiz_id)
    if q is None or q.status != "approved":
        raise NotFoundError("Test topilmadi.")

    questions = q.questions or []
    if len(payload.answers) != len(questions):
        from app.core.exceptions import AppError
        raise AppError("Javoblar soni savollarga mos kelmaydi.", status_code=400)

    correct = sum(
        1 for i, ans in enumerate(payload.answers)
        if i < len(questions) and questions[i].get("correct_index") == ans
    )
    total = len(questions)
    score = round(correct / total * 100) if total else 0

    attempt = QuizAttempt(
        quiz_id=quiz_id,
        user_id=user.id,
        answers=payload.answers,
        score=score,
        correct_count=correct,
        total_count=total,
    )
    db.add(attempt)
    await db.commit()
    await db.refresh(attempt)
    return attempt


# ─── Curator endpoints ───

@router.post("", response_model=QuizRead, status_code=201)
async def create_quiz(
    payload: QuizCreate, db: DbSession, user: CuratorUser
) -> QuizRead:
    q = Quiz(
        title=payload.title,
        description=payload.description,
        difficulty=payload.difficulty,
        questions=[item.model_dump() for item in payload.questions],
        category=payload.category,
        cover_image_url=payload.cover_image_url,
        video_url=payload.video_url,
        status="draft",
        created_by_id=user.id,
    )
    db.add(q)
    await db.commit()
    await db.refresh(q)
    return _to_read(q)


@router.post("/{quiz_id}/image", response_model=QuizRead)
async def upload_quiz_image(
    quiz_id: uuid.UUID,
    db: DbSession,
    user: CuratorUser,
    file: UploadFile = File(...),
) -> QuizRead:
    q = await db.get(Quiz, quiz_id)
    if q is None or q.created_by_id != user.id:
        raise NotFoundError("Test topilmadi.")
    content_type = file.content_type or ""
    if not content_type.startswith("image/"):
        raise AppError("Faqat rasm fayllari qabul qilinadi (image/*).", status_code=400)
    data = await file.read()
    if not data:
        raise AppError("Rasm fayl bo'sh.", status_code=400)
    max_bytes = 10 * 1024 * 1024
    if len(data) > max_bytes:
        raise AppError("Rasm hajmi 10MB dan oshmasligi kerak.", status_code=413)
    url = await storage.save_bytes(
        data,
        folder="quiz_images",
        filename=file.filename or "image.jpg",
        content_type=content_type,
    )
    q.cover_image_url = url
    await db.commit()
    await db.refresh(q)
    return _to_read(q)


@router.post("/{quiz_id}/video", response_model=QuizRead)
async def upload_quiz_video(
    quiz_id: uuid.UUID,
    db: DbSession,
    user: CuratorUser,
    file: UploadFile = File(...),
) -> QuizRead:
    q = await db.get(Quiz, quiz_id)
    if q is None or q.created_by_id != user.id:
        raise NotFoundError("Test topilmadi.")
    content_type = file.content_type or ""
    if not content_type.startswith("video/"):
        raise AppError("Faqat video fayllari qabul qilinadi (video/*).", status_code=400)
    data = await file.read()
    if not data:
        raise AppError("Video fayl bo'sh.", status_code=400)
    max_mb = getattr(settings, "quiz_video_max_mb", 200)
    max_bytes = max_mb * 1024 * 1024
    if len(data) > max_bytes:
        raise AppError(
            f"Video hajmi {max_mb}MB dan oshmasligi kerak.", status_code=413
        )
    url = await storage.save_bytes(
        data,
        folder="quiz_videos",
        filename=file.filename or "video.mp4",
        content_type=content_type,
    )
    q.video_url = url
    await db.commit()
    await db.refresh(q)
    return _to_read(q)


@router.get("/my/drafts", response_model=list[QuizRead])
async def my_drafts(db: DbSession, user: CuratorUser) -> list[QuizRead]:
    rows = (
        await db.execute(
            select(Quiz)
            .where(Quiz.created_by_id == user.id)
            .order_by(Quiz.created_at.desc())
        )
    ).scalars().all()
    return [_to_read(q) for q in rows]


# ─── Admin endpoints ───

@router.get("/admin/pending", response_model=list[QuizRead])
async def pending_quizzes(db: DbSession, user: AdminUser) -> list[QuizRead]:
    rows = (
        await db.execute(
            select(Quiz)
            .where(Quiz.status == "draft")
            .order_by(Quiz.created_at)
        )
    ).scalars().all()
    return [_to_read(q) for q in rows]


@router.get("/admin/all", response_model=list[QuizRead])
async def all_quizzes(db: DbSession, user: AdminUser) -> list[QuizRead]:
    rows = (
        await db.execute(select(Quiz).order_by(Quiz.created_at.desc()))
    ).scalars().all()
    return [_to_read(q) for q in rows]


@router.get("/admin/{quiz_id}", response_model=QuizDetail)
async def admin_get_quiz(quiz_id: uuid.UUID, db: DbSession, user: AdminUser) -> QuizDetail:
    q = await db.get(Quiz, quiz_id)
    if q is None:
        raise NotFoundError("Test topilmadi.")
    return QuizDetail(
        id=q.id, title=q.title, description=q.description,
        difficulty=q.difficulty, status=q.status, category=q.category,
        question_count=len(q.questions or []), created_at=q.created_at,
        cover_image_url=q.cover_image_url, video_url=q.video_url,
        questions=q.questions or [],
    )


@router.patch("/admin/{quiz_id}/approve", response_model=QuizRead)
async def approve_quiz(
    quiz_id: uuid.UUID, db: DbSession, user: AdminUser
) -> QuizRead:
    q = await db.get(Quiz, quiz_id)
    if q is None:
        raise NotFoundError("Test topilmadi.")
    q.status = "approved"
    q.approved_by_id = user.id
    await db.commit()
    await db.refresh(q)
    return _to_read(q)


@router.patch("/admin/{quiz_id}/reject", response_model=QuizRead)
async def reject_quiz(
    quiz_id: uuid.UUID, db: DbSession, user: AdminUser
) -> QuizRead:
    q = await db.get(Quiz, quiz_id)
    if q is None:
        raise NotFoundError("Test topilmadi.")
    q.status = "rejected"
    await db.commit()
    await db.refresh(q)
    return _to_read(q)
