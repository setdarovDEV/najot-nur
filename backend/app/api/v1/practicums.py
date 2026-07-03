"""Practicum endpoints — curator creates, admin approves, users listen on mobile."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, File, Form, UploadFile
from sqlalchemy import desc, select

from app.api.deps import AdminUser, CuratorUser, DbSession, EnrolledUser
from app.core.config import settings
from app.core.exceptions import AppError, NotFoundError
from app.core.logging import get_logger
from app.models.analysis import VoiceAnalysis
from app.models.enums import AnalysisStatus
from app.models.practicum import Practicum
from app.models.practicum_submission import PracticumSubmission
from app.models.user import User
from app.schemas.practicum import (
    PracticumCreate,
    PracticumRead,
    PracticumSubmissionRead,
)
from app.services import storage
from app.services.ai import analyze_voice, transcribe

router = APIRouter()
log = get_logger("practicums")


def _to_read(p: Practicum) -> PracticumRead:
    return PracticumRead(
        id=p.id,
        title=p.title,
        description=p.description,
        category=p.category,
        expert_text=p.expert_text,
        expert_audio_url=p.expert_audio_url,
        is_free=p.is_free,
        price=float(p.price),
        status=p.status,
        created_at=p.created_at,
    )


async def _transcribe_expert_audio(p: Practicum, db: DbSession) -> None:
    """Best-effort STT pass on the practicum's expert audio. Stores the
    transcript on ``p.expert_transcript`` so the analysis pipeline doesn't
    re-run STT for every user submission."""
    if not p.expert_audio_url:
        return
    if p.expert_transcript:
        return  # already cached
    if not settings.stt_enabled:
        return
    data = await storage.load_bytes(p.expert_audio_url)
    if not data:
        return
    filename = p.expert_audio_url.rsplit("/", 1)[-1] or "expert.m4a"
    result = await transcribe(
        data=data,
        filename=filename,
        content_type="audio/mp4",
        language=settings.stt_language,
    )
    if result and result.get("text"):
        p.expert_transcript = result["text"].strip()
        log.info(
            "practicum.expert_transcribed",
            practicum_id=str(p.id),
            length=len(p.expert_transcript),
        )


# ─── Public / user endpoints ───

@router.get("", response_model=list[PracticumRead])
async def list_practicums(db: DbSession, user: EnrolledUser) -> list[PracticumRead]:
    rows = (
        await db.execute(
            select(Practicum)
            .where(Practicum.status == "approved")
            .order_by(Practicum.created_at.desc())
        )
    ).scalars().all()
    return [_to_read(p) for p in rows]


@router.get("/{practicum_id}", response_model=PracticumRead)
async def get_practicum(practicum_id: uuid.UUID, db: DbSession, user: EnrolledUser) -> PracticumRead:
    p = await db.get(Practicum, practicum_id)
    if p is None or p.status != "approved":
        raise NotFoundError("Praktikum topilmadi.")
    return _to_read(p)


# ─── Submission endpoints ───

@router.post("/{practicum_id}/submit", response_model=PracticumSubmissionRead, status_code=201)
async def submit_practicum(
    practicum_id: uuid.UUID,
    db: DbSession,
    user: EnrolledUser,
    file: UploadFile = File(...),
    language: str | None = Form(None),
) -> PracticumSubmissionRead:
    """Submit a voice recording for a practicum exercise."""
    p = await db.get(Practicum, practicum_id)
    if p is None or p.status != "approved":
        raise NotFoundError("Praktikum topilmadi.")

    # Validate audio
    content_type = file.content_type or ""
    if not content_type.startswith("audio/") and content_type != "video/webm":
        raise AppError("Faqat audio fayllari qabul qilinadi (audio/*).", status_code=400)
    data = await file.read()
    if not data:
        raise AppError("Audio fayl bo'sh.", status_code=400)
    max_bytes = settings.stt_max_audio_mb * 1024 * 1024
    if len(data) > max_bytes:
        raise AppError(
            f"Audio fayl hajmi {settings.stt_max_audio_mb}MB dan oshmasligi kerak.",
            status_code=413,
        )

    # Save audio to storage
    filename = file.filename or "submission.webm"
    audio_url = await storage.save_bytes(
        data,
        folder="practicum_submissions",
        filename=filename,
        content_type=content_type,
    )

    # Create submission record with pending status
    submission = PracticumSubmission(
        user_id=user.id,
        practicum_id=practicum_id,
        audio_url=audio_url,
        status="pending",
    )
    db.add(submission)
    await db.flush()

    # Run STT
    stt_text: str | None = None
    if settings.stt_enabled:
        lang = (language or settings.stt_language).lower()
        stt_result = await transcribe(
            data=data, filename=filename, content_type=content_type, language=lang
        )
        if stt_result and stt_result.get("text"):
            stt_text = stt_result["text"]

    # Make sure the expert audio is transcribed at least once so we have a
    # reference text for the AI comparison even when the curator only
    # uploaded audio (without typing expert_text).
    await _transcribe_expert_audio(p, db)

    # Pick the best reference text: curator-typed > STT of expert audio.
    reference_text = (p.expert_text or "").strip() or (p.expert_transcript or "").strip() or None

    # Run voice analysis if we have a transcript and reference text
    analysis_fields: dict = {}
    voice_analysis_id: uuid.UUID | None = None
    overall_score: int | None = None

    if stt_text and reference_text:
        result = await analyze_voice(
            reference_text=reference_text,
            transcript=stt_text,
        )
        va = VoiceAnalysis(
            user_id=user.id,
            reference_text=reference_text,
            audio_url=audio_url,
            transcript=stt_text,
            status=AnalysisStatus.done,
            **result,
        )
        db.add(va)
        await db.flush()
        voice_analysis_id = va.id
        overall_score = result.get("overall_score")
        analysis_fields = {
            "accuracy_score": result.get("accuracy_score"),
            "word_errors": result.get("word_errors"),
            "word_analysis": result.get("word_analysis"),
            "char_stats": result.get("char_stats"),
            "phoneme_errors": result.get("phoneme_errors"),
            "summary": result.get("summary"),
        }

    # Update submission
    submission.transcript = stt_text
    submission.voice_analysis_id = voice_analysis_id
    submission.overall_score = overall_score
    submission.status = "done" if stt_text is not None else "failed"
    await db.commit()
    await db.refresh(submission)

    return PracticumSubmissionRead(
        id=submission.id,
        practicum_id=submission.practicum_id,
        audio_url=submission.audio_url,
        transcript=submission.transcript,
        overall_score=submission.overall_score,
        status=submission.status,
        created_at=submission.created_at,
        **analysis_fields,
    )


@router.get("/{practicum_id}/my-submission", response_model=PracticumSubmissionRead)
async def my_submission(
    practicum_id: uuid.UUID,
    db: DbSession,
    user: EnrolledUser,
) -> PracticumSubmissionRead:
    """Return the user's latest submission for this practicum."""
    row = (
        await db.execute(
            select(PracticumSubmission)
            .where(
                PracticumSubmission.user_id == user.id,
                PracticumSubmission.practicum_id == practicum_id,
            )
            .order_by(PracticumSubmission.created_at.desc())
            .limit(1)
        )
    ).scalar_one_or_none()

    if row is None:
        raise NotFoundError("Topshiriq topilmadi.")

    # Fetch voice analysis to flatten fields
    analysis_fields: dict = {}
    if row.voice_analysis_id is not None:
        va = await db.get(VoiceAnalysis, row.voice_analysis_id)
        if va is not None:
            analysis_fields = {
                "accuracy_score": va.accuracy_score,
                "word_errors": va.word_errors,
                "word_analysis": va.word_analysis,
                "char_stats": va.char_stats,
                "phoneme_errors": va.phoneme_errors,
                "summary": va.summary,
            }

    return PracticumSubmissionRead(
        id=row.id,
        practicum_id=row.practicum_id,
        audio_url=row.audio_url,
        transcript=row.transcript,
        overall_score=row.overall_score,
        status=row.status,
        created_at=row.created_at,
        **analysis_fields,
    )


# ─── Curator endpoints ───

@router.post("", response_model=PracticumRead, status_code=201)
async def create_practicum(
    payload: PracticumCreate, db: DbSession, user: CuratorUser
) -> PracticumRead:
    p = Practicum(
        title=payload.title,
        description=payload.description,
        category=payload.category,
        expert_text=payload.expert_text,
        is_free=payload.is_free,
        price=payload.price if not payload.is_free else 0,
        status="draft",
        created_by_id=user.id,
    )
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return _to_read(p)


@router.post("/{practicum_id}/audio", response_model=PracticumRead)
async def upload_practicum_audio(
    practicum_id: uuid.UUID,
    db: DbSession,
    user: CuratorUser,
    file: UploadFile = File(...),
) -> PracticumRead:
    p = await db.get(Practicum, practicum_id)
    if p is None or p.created_by_id != user.id:
        raise NotFoundError("Praktikum topilmadi.")
    data = await file.read()
    url = await storage.save_bytes(
        data,
        folder="practicums",
        filename=file.filename or "audio.mp3",
        content_type=file.content_type,
    )
    p.expert_audio_url = url
    # Drop the cached transcript so it gets re-derived from the new audio.
    p.expert_transcript = None
    await _transcribe_expert_audio(p, db)
    await db.commit()
    await db.refresh(p)
    return _to_read(p)


@router.get("/my/drafts", response_model=list[PracticumRead])
async def my_drafts(db: DbSession, user: CuratorUser) -> list[PracticumRead]:
    rows = (
        await db.execute(
            select(Practicum)
            .where(Practicum.created_by_id == user.id)
            .order_by(Practicum.created_at.desc())
        )
    ).scalars().all()
    return [_to_read(p) for p in rows]


# ─── Curator / admin: submissions review ─────────────────────────────────────

async def _submission_to_read(
    row: PracticumSubmission,
    db: DbSession,
    user: User | None = None,
    reference_text: str | None = None,
) -> PracticumSubmissionRead:
    """Flatten a PracticumSubmission row + its VoiceAnalysis into the read shape."""
    analysis_fields: dict = {}
    if row.voice_analysis_id is not None:
        va = await db.get(VoiceAnalysis, row.voice_analysis_id)
        if va is not None:
            analysis_fields = {
                "accuracy_score": va.accuracy_score,
                "word_errors": va.word_errors,
                "word_analysis": va.word_analysis,
                "char_stats": va.char_stats,
                "phoneme_errors": va.phoneme_errors,
                "summary": va.summary,
                "reference_text": va.reference_text,
            }
    return PracticumSubmissionRead(
        id=row.id,
        practicum_id=row.practicum_id,
        audio_url=row.audio_url,
        transcript=row.transcript,
        overall_score=row.overall_score,
        status=row.status,
        created_at=row.created_at,
        user_full_name=user.full_name if user else None,
        user_phone=user.phone if user else None,
        reference_text=reference_text,
        **analysis_fields,
    )


@router.get("/{practicum_id}/submissions", response_model=list[PracticumSubmissionRead])
async def list_practicum_submissions(
    practicum_id: uuid.UUID,
    db: DbSession,
    _: CuratorUser,
) -> list[PracticumSubmissionRead]:
    """List all user submissions for a practicum (curator / admin view)."""
    p = await db.get(Practicum, practicum_id)
    if p is None:
        raise NotFoundError("Praktikum topilmadi.")

    rows = (
        await db.execute(
            select(PracticumSubmission, User)
            .join(User, User.id == PracticumSubmission.user_id)
            .where(PracticumSubmission.practicum_id == practicum_id)
            .order_by(desc(PracticumSubmission.created_at))
            .limit(500)
        )
    ).all()

    out: list[PracticumSubmissionRead] = []
    for sub, usr in rows:
        out.append(
            await _submission_to_read(
                sub,
                db,
                user=usr,
                reference_text=(p.expert_text or p.expert_transcript),
            )
        )
    return out


@router.get(
    "/{practicum_id}/submissions/{submission_id}",
    response_model=PracticumSubmissionRead,
)
async def get_practicum_submission(
    practicum_id: uuid.UUID,
    submission_id: uuid.UUID,
    db: DbSession,
    _: CuratorUser,
) -> PracticumSubmissionRead:
    p = await db.get(Practicum, practicum_id)
    if p is None:
        raise NotFoundError("Praktikum topilmadi.")
    sub = await db.get(PracticumSubmission, submission_id)
    if sub is None or sub.practicum_id != practicum_id:
        raise NotFoundError("Topshiriq topilmadi.")
    usr = await db.get(User, sub.user_id)
    return await _submission_to_read(
        sub,
        db,
        user=usr,
        reference_text=(p.expert_text or p.expert_transcript),
    )


# ─── Admin endpoints ───

@router.get("/admin/all", response_model=list[PracticumRead])
async def all_practicums(db: DbSession, user: AdminUser) -> list[PracticumRead]:
    rows = (
        await db.execute(select(Practicum).order_by(Practicum.created_at.desc()))
    ).scalars().all()
    return [_to_read(p) for p in rows]


@router.get("/admin/pending", response_model=list[PracticumRead])
async def pending_practicums(db: DbSession, user: AdminUser) -> list[PracticumRead]:
    rows = (
        await db.execute(
            select(Practicum)
            .where(Practicum.status == "draft")
            .order_by(Practicum.created_at)
        )
    ).scalars().all()
    return [_to_read(p) for p in rows]


@router.get("/admin/{practicum_id}", response_model=PracticumRead)
async def admin_get_practicum(practicum_id: uuid.UUID, db: DbSession, user: AdminUser) -> PracticumRead:
    p = await db.get(Practicum, practicum_id)
    if p is None:
        raise NotFoundError("Praktikum topilmadi.")
    return _to_read(p)


@router.patch("/admin/{practicum_id}/approve", response_model=PracticumRead)
async def approve_practicum(
    practicum_id: uuid.UUID, db: DbSession, user: AdminUser
) -> PracticumRead:
    p = await db.get(Practicum, practicum_id)
    if p is None:
        raise NotFoundError("Praktikum topilmadi.")
    p.status = "approved"
    p.approved_by_id = user.id
    await db.commit()
    await db.refresh(p)
    return _to_read(p)


@router.patch("/admin/{practicum_id}/reject", response_model=PracticumRead)
async def reject_practicum(
    practicum_id: uuid.UUID, db: DbSession, user: AdminUser
) -> PracticumRead:
    p = await db.get(Practicum, practicum_id)
    if p is None:
        raise NotFoundError("Praktikum topilmadi.")
    p.status = "rejected"
    await db.commit()
    await db.refresh(p)
    return _to_read(p)
