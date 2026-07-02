"""Admin & curator panel API: clients, homework grading, audiobooks, push.

Permission model
----------------
* curator  → uploads audiobooks, video lessons, grades homework
* admin    → manages curators, views all sections, sends push, payments
"""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, File, Form, Query, UploadFile
from slugify import slugify  # type: ignore
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import AdminUser, CuratorUser, DbSession
from app.core.exceptions import AppError, ConflictError, NotFoundError
from app.core.logging import get_logger
from app.core.security import hash_password
from app.models.analysis import PronunciationReference, SpeechAnalysis
from app.models.audiobook import Audiobook, AudiobookPage
from app.models.certificate_request import CertificateRequest
from app.models.course import Course, Enrollment, Lesson, LessonQuestion
from app.models.enums import AuthProvider, CertificateRequestStatus, HomeworkStatus, PushAudience, Role
from app.models.grading import Homework
from app.models.notification import PushNotification, PushToken
from app.models.user import AuthIdentity, User
from app.schemas.admin import (
    ClientRow,
    CuratorCreate,
    CuratorRead,
    CuratorUpdate,
    GradeRequest,
    HomeworkRow,
    PushCreate,
    PushRead,
)
from app.schemas.audiobook import (
    AudiobookCreate,
    AudiobookDetail,
    AudiobookPageUpsert,
    AudiobookRead,
    AudiobookUpdate,
)
from app.schemas.common import Message, Page
from app.services import storage

router = APIRouter()
log = get_logger("admin")


# ───────────────────── Dashboard ─────────────────────
@router.get("/stats")
async def stats(_: CuratorUser, db: DbSession) -> dict:
    async def count(model) -> int:
        return (await db.execute(select(func.count(model.id)))).scalar_one()

    pending_hw = (
        await db.execute(
            select(func.count(Homework.id)).where(
                Homework.status == HomeworkStatus.submitted
            )
        )
    ).scalar_one()
    pending_cert_reqs = (
        await db.execute(
            select(func.count(CertificateRequest.id)).where(
                CertificateRequest.status == CertificateRequestStatus.pending
            )
        )
    ).scalar_one()
    return {
        "users": await count(User),
        "audiobooks": await count(Audiobook),
        "speech_analyses": await count(SpeechAnalysis),
        "pending_homeworks": pending_hw,
        "pending_certificate_requests": pending_cert_reqs,
    }


# ───────────────────── Clients (admin only) ─────────────────────
@router.get("/clients", response_model=Page[ClientRow])
async def clients(
    db: DbSession,
    _: AdminUser,
    q: str | None = Query(None, description="search by name/phone/email"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
) -> Page[ClientRow]:
    base = select(User)
    if q:
        like = f"%{q}%"
        base = base.where(
            or_(User.full_name.ilike(like), User.phone.ilike(like), User.email.ilike(like))
        )

    total = (
        await db.execute(select(func.count()).select_from(base.subquery()))
    ).scalar_one()
    users = (
        await db.execute(
            base.order_by(User.created_at.desc())
            .offset((page - 1) * size)
            .limit(size)
        )
    ).scalars().all()

    # Latest speech analysis per listed user (one extra query, picked in Python).
    user_ids = [u.id for u in users]
    latest: dict[uuid.UUID, SpeechAnalysis] = {}
    if user_ids:
        rows = (
            await db.execute(
                select(SpeechAnalysis)
                .where(SpeechAnalysis.user_id.in_(user_ids))
                .order_by(SpeechAnalysis.created_at.desc())
            )
        ).scalars().all()
        for r in rows:
            latest.setdefault(r.user_id, r)

    items = [
        ClientRow(
            id=u.id,
            full_name=u.full_name,
            phone=u.phone,
            email=u.email,
            is_verified=u.is_verified,
            created_at=u.created_at,
            last_speech_score=latest[u.id].overall_score if u.id in latest else None,
            last_speech_summary=latest[u.id].summary if u.id in latest else None,
        )
        for u in users
    ]
    return Page[ClientRow](items=items, total=total, page=page, size=size)


@router.get("/clients/{user_id}")
async def client_detail(user_id: uuid.UUID, _: AdminUser, db: DbSession) -> dict:
    user = await db.get(User, user_id)
    if user is None:
        raise NotFoundError("Mijoz topilmadi.")
    analyses = (
        await db.execute(
            select(SpeechAnalysis)
            .where(SpeechAnalysis.user_id == user_id)
            .order_by(SpeechAnalysis.created_at.desc())
            .limit(10)
        )
    ).scalars().all()
    return {
        "id": str(user.id),
        "full_name": user.full_name,
        "phone": user.phone,
        "email": user.email,
        "is_verified": user.is_verified,
        "created_at": user.created_at.isoformat(),
        "speech_analyses": [
            {
                "id": str(a.id),
                "overall_score": a.overall_score,
                "summary": a.summary,
                "created_at": a.created_at.isoformat(),
            }
            for a in analyses
        ],
    }


# ───────────────────── Homework grading (curators) ─────────────────────
@router.get("/homeworks", response_model=list[HomeworkRow])
async def list_homeworks(
    db: DbSession,
    _: CuratorUser,
    status: HomeworkStatus | None = None,
) -> list[Homework]:
    """List homework submissions with the student and lesson joined in so the
    curator can see who submitted what without an extra round-trip."""
    stmt = (
        select(Homework, User, Lesson)
        .join(User, User.id == Homework.user_id)
        .join(Lesson, Lesson.id == Homework.lesson_id)
        .order_by(Homework.created_at.desc())
    )
    if status:
        stmt = stmt.where(Homework.status == status)
    stmt = stmt.limit(200)

    rows = (await db.execute(stmt)).all()
    out: list[HomeworkRow] = []
    for hw, user, lesson in rows:
        out.append(
            HomeworkRow(
                id=hw.id,
                user_id=hw.user_id,
                lesson_id=hw.lesson_id,
                status=hw.status,
                submission_text=hw.submission_text,
                submission_url=hw.submission_url,
                curator_score=hw.curator_score,
                curator_feedback=hw.curator_feedback,
                reviewed_at=hw.reviewed_at,
                created_at=hw.created_at,
                user_full_name=user.full_name,
                user_phone=user.phone,
                lesson_title=lesson.title,
            )
        )
    return out


@router.post("/homeworks/{homework_id}/grade", response_model=HomeworkRow)
async def grade_homework(
    homework_id: uuid.UUID,
    payload: GradeRequest,
    curator: CuratorUser,
    db: DbSession,
) -> Homework:
    hw = await db.get(Homework, homework_id)
    if hw is None:
        raise NotFoundError("Uy vazifasi topilmadi.")
    hw.curator_id = curator.id
    hw.curator_score = payload.score
    hw.curator_feedback = payload.feedback
    hw.status = HomeworkStatus.reviewed
    hw.reviewed_at = datetime.now(UTC)
    await db.flush()

    # Notify the student about the grade. Bad grades (<60) get a strong
    # "⚠️ yomon baho" tone in the body; good grades get a celebratory one.
    try:
        await _notify_homework_graded(db, hw, payload.feedback)
    except Exception as exc:  # noqa: BLE001
        log.error(
            "homework.grade_notify_failed",
            homework_id=str(homework_id),
            error=str(exc),
        )

    return hw


async def _notify_homework_graded(
    db: AsyncSession,
    hw: Homework,
    feedback: str | None,
) -> None:
    """Best-effort FCM + in-app push to the student for a graded homework."""
    from app.services import fcm

    lesson = await db.get(Lesson, hw.lesson_id)
    lesson_title = lesson.title if lesson else "dars"
    score = hw.curator_score or 0

    BAD_GRADE_THRESHOLD = 60
    is_bad = score < BAD_GRADE_THRESHOLD
    title = (
        "⚠️ Yomon baho — qayta ko'rib chiqing"
        if is_bad
        else "Uy vazifasi baholandi ✅"
    )
    feedback_suffix = f"\n💬 Curator izohi: {feedback}" if feedback else ""
    body = (
        f'"{lesson_title}" darsi uchun uy vazifangiz {score}/100 baho oldi.'
        f"{feedback_suffix}"
    )

    tokens = (
        await db.execute(
            select(PushToken.token).where(PushToken.user_id == hw.user_id)
        )
    ).scalars().all()
    if tokens:
        await fcm.send_to_tokens(
            tokens,
            title=title,
            body=body,
            data={
                "kind": "homework_graded",
                "homework_id": str(hw.id),
                "lesson_id": str(hw.lesson_id),
                "score": str(score),
                "is_bad_grade": "1" if is_bad else "0",
            },
        )

    db.add(
        PushNotification(
            title=title,
            body=body,
            audience=PushAudience.user,
            target_id=hw.user_id,
            sent_by=hw.curator_id,
            sent_at=datetime.now(UTC),
        )
    )
    await db.flush()


# ───────────────────── Audiobooks management (curator) ─────────────────────
@router.get("/audiobooks", response_model=list[AudiobookRead])
async def list_all_audiobooks(_: CuratorUser, db: DbSession) -> list[Audiobook]:
    rows = (
        await db.execute(select(Audiobook).order_by(Audiobook.created_at.desc()))
    ).scalars().all()
    return list(rows)


@router.post("/audiobooks", response_model=AudiobookRead)
async def create_audiobook(
    payload: AudiobookCreate, _: CuratorUser, db: DbSession
) -> Audiobook:
    book = Audiobook(
        title=payload.title,
        slug=slugify(payload.title),
        author=payload.author,
        description=payload.description,
        category=payload.category,
        is_free=payload.is_free,
        price=payload.price,
        cover_url=payload.cover_url,
    )
    db.add(book)
    await db.flush()
    return book


@router.patch("/audiobooks/{audiobook_id}", response_model=AudiobookRead)
async def update_audiobook(
    audiobook_id: uuid.UUID,
    payload: AudiobookUpdate,
    _: CuratorUser,
    db: DbSession,
) -> Audiobook:
    """Update audiobook metadata."""
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")

    if payload.title is not None:
        book.title = payload.title
        book.slug = slugify(payload.title)
    if payload.author is not None:
        book.author = payload.author
    if payload.description is not None:
        book.description = payload.description
    if payload.category is not None:
        book.category = payload.category
    if payload.is_free is not None:
        book.is_free = payload.is_free
    if payload.price is not None:
        book.price = payload.price

    await db.flush()
    log.info("audiobook.updated", audiobook_id=str(audiobook_id))
    return book


@router.put("/audiobooks/{audiobook_id}/pages", response_model=Message)
async def upsert_page(
    audiobook_id: uuid.UUID,
    payload: AudiobookPageUpsert,
    _: CuratorUser,
    db: DbSession,
) -> Message:
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")

    page = (
        await db.execute(
            select(AudiobookPage).where(
                AudiobookPage.audiobook_id == audiobook_id,
                AudiobookPage.page_number == payload.page_number,
            )
        )
    ).scalar_one_or_none()
    if page is None:
        page = AudiobookPage(audiobook_id=audiobook_id, page_number=payload.page_number)
        db.add(page)
    page.content = payload.content
    page.audio_url = payload.audio_url
    await db.flush()

    book.total_pages = (
        await db.execute(
            select(func.count(AudiobookPage.id)).where(
                AudiobookPage.audiobook_id == audiobook_id
            )
        )
    ).scalar_one()
    return Message(message="Sahifa saqlandi.")


@router.post("/audiobooks/{audiobook_id}/publish", response_model=Message)
async def publish_audiobook(
    audiobook_id: uuid.UUID, _: AdminUser, db: DbSession
) -> Message:
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")
    book.is_published = True
    return Message(message="Audiokitob nashr qilindi.")


@router.get("/audiobooks/{audiobook_id}", response_model=AudiobookDetail)
async def get_audiobook_admin(
    audiobook_id: uuid.UUID, _: CuratorUser, db: DbSession
) -> Audiobook:
    """Return an audiobook with all its pages eagerly loaded."""
    result = await db.execute(
        select(Audiobook)
        .where(Audiobook.id == audiobook_id)
        .options(selectinload(Audiobook.pages))
    )
    book = result.scalar_one_or_none()
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")
    return book


@router.post("/audiobooks/{audiobook_id}/cover", response_model=AudiobookRead)
async def upload_cover(
    audiobook_id: uuid.UUID,
    file: UploadFile = File(...),
    _: CuratorUser = ...,  # type: ignore[assignment]
    db: DbSession = ...,  # type: ignore[assignment]
) -> Audiobook:
    """Upload a cover image and update the audiobook's cover_url."""
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")

    content_type = file.content_type or ""
    if not content_type.startswith("image/"):
        raise AppError("Faqat rasm fayllari qabul qilinadi (image/*).", status_code=400)

    data = await file.read()
    url = await storage.save_bytes(
        data,
        folder="covers",
        filename=file.filename or "cover",
        content_type=content_type,
    )
    book.cover_url = url
    await db.flush()
    log.info("audiobook.cover_uploaded", audiobook_id=str(audiobook_id), url=url)
    return book


@router.post("/audiobooks/{audiobook_id}/pages/{page_number}/audio", response_model=Message)
async def upload_page_audio(
    audiobook_id: uuid.UUID,
    page_number: int,
    file: UploadFile = File(...),
    _: CuratorUser = ...,  # type: ignore[assignment]
    db: DbSession = ...,  # type: ignore[assignment]
) -> Message:
    """Upload an audio file for a specific audiobook page (upsert)."""
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")

    content_type = file.content_type or ""
    if not content_type.startswith("audio/"):
        raise AppError("Faqat audio fayllari qabul qilinadi (audio/*).", status_code=400)

    data = await file.read()
    url = await storage.save_bytes(
        data,
        folder="audiobooks",
        filename=file.filename or f"page_{page_number}.mp3",
        content_type=content_type,
    )

    page = (
        await db.execute(
            select(AudiobookPage).where(
                AudiobookPage.audiobook_id == audiobook_id,
                AudiobookPage.page_number == page_number,
            )
        )
    ).scalar_one_or_none()

    if page is None:
        page = AudiobookPage(audiobook_id=audiobook_id, page_number=page_number)
        db.add(page)
        # Update total_pages if this is a new page
        book.total_pages = (
            await db.execute(
                select(func.count(AudiobookPage.id)).where(
                    AudiobookPage.audiobook_id == audiobook_id
                )
            )
        ).scalar_one() + 1

    page.audio_url = url
    await db.flush()
    log.info(
        "audiobook.audio_uploaded",
        audiobook_id=str(audiobook_id),
        page_number=page_number,
        url=url,
    )
    return Message(message="Audio fayl yuklandi.")


@router.post("/audiobooks/{audiobook_id}/audio")
async def upload_audiobook_audio(
    audiobook_id: uuid.UUID,
    _: CuratorUser,
    db: DbSession,
    file: UploadFile = File(...),
) -> dict:
    """Upload a single audio file for the whole audiobook."""
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")
    if not (file.content_type or "").startswith("audio/"):
        raise AppError("Faqat audio fayllari qabul qilinadi (audio/*).", status_code=400)
    data = await file.read()
    ext = (file.filename or "audio.mp3").rsplit(".", 1)[-1]
    url = await storage.save_bytes(
        data,
        folder="audiobooks",
        filename=f"main_{audiobook_id}.{ext}",
        content_type=file.content_type or "audio/mpeg",
    )
    book.audio_url = url
    await db.flush()
    log.info("audiobook.audio_uploaded", audiobook_id=str(audiobook_id), url=url)
    return {"audio_url": url}


@router.delete("/audiobooks/{audiobook_id}", response_model=Message)
async def delete_audiobook(
    audiobook_id: uuid.UUID, _: CuratorUser, db: DbSession
) -> Message:
    """Delete an audiobook and all its pages (cascade)."""
    book = await db.get(Audiobook, audiobook_id)
    if book is None:
        raise NotFoundError("Audiokitob topilmadi.")
    await db.delete(book)
    await db.flush()
    log.info("audiobook.deleted", audiobook_id=str(audiobook_id))
    return Message(message="Audiokitob o'chirildi.")


@router.delete("/audiobooks/{audiobook_id}/pages/{page_number}", response_model=Message)
async def delete_page(
    audiobook_id: uuid.UUID, page_number: int, _: CuratorUser, db: DbSession
) -> Message:
    """Delete a specific audiobook page and update the book's total_pages count."""
    page = (
        await db.execute(
            select(AudiobookPage).where(
                AudiobookPage.audiobook_id == audiobook_id,
                AudiobookPage.page_number == page_number,
            )
        )
    ).scalar_one_or_none()
    if page is None:
        raise NotFoundError("Sahifa topilmadi.")

    await db.delete(page)
    await db.flush()

    # Recalculate total_pages
    book = await db.get(Audiobook, audiobook_id)
    if book is not None:
        book.total_pages = (
            await db.execute(
                select(func.count(AudiobookPage.id)).where(
                    AudiobookPage.audiobook_id == audiobook_id
                )
            )
        ).scalar_one()
        await db.flush()

    log.info(
        "audiobook.page_deleted",
        audiobook_id=str(audiobook_id),
        page_number=page_number,
    )
    return Message(message="Sahifa o'chirildi.")


# ───────────────────── Users (admin) ─────────────────────
@router.get("/users")
async def list_users(
    _: AdminUser, db: DbSession, q: str = Query("", description="Search by phone, name, email")
) -> list[dict]:
    stmt = select(User).order_by(User.created_at.desc()).limit(200)
    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            or_(
                User.phone.ilike(like),
                User.full_name.ilike(like),
                User.email.ilike(like),
            )
        )
    rows = (await db.execute(stmt)).scalars().all()
    return [
        {
            "id": str(u.id),
            "full_name": u.full_name,
            "phone": u.phone,
            "email": u.email,
            "is_active": u.is_active,
        }
        for u in rows
    ]


# ───────────────────── Push notifications (admin) ─────────────────────
@router.post("/push", response_model=PushRead)
async def send_push(
    payload: PushCreate, admin: AdminUser, db: DbSession
) -> PushNotification:
    if payload.audience in {PushAudience.course, PushAudience.user} and not payload.target_id:
        raise AppError(
            status_code=422,
            code="push.target_required",
            message="Kurs yoki foydalanuvchi tanlang.",
        )

    token_select_stmt = select(PushToken)
    if payload.audience == PushAudience.user and payload.target_id:
        token_select_stmt = token_select_stmt.where(
            PushToken.user_id == payload.target_id
        )
    elif payload.audience == PushAudience.course and payload.target_id:
        enrolled = select(Enrollment.user_id).where(
            Enrollment.course_id == payload.target_id
        )
        token_select_stmt = token_select_stmt.where(
            PushToken.user_id.in_(enrolled)
        )
    rows = (await db.execute(token_select_stmt)).scalars().all()
    target_tokens = [t.token for t in rows]

    notif = PushNotification(
        title=payload.title,
        body=payload.body,
        audience=payload.audience,
        target_id=payload.target_id,
        sent_by=admin.id,
        sent_at=datetime.now(UTC),
        delivered_count=0,
    )
    db.add(notif)
    await db.flush()

    # Deliver via FCM. Service is a no-op when not configured, in which case
    # we still consider the message "delivered" to the user via the in-app
    # /users/me/notifications feed, so we count the target row count.
    from app.services import fcm

    fcm_result = await fcm.send_to_tokens(
        target_tokens,
        title=payload.title,
        body=payload.body,
        data={
            "notification_id": str(notif.id),
            "audience": payload.audience.value,
        },
    )

    if fcm_result["success"] or fcm_result["failure"]:
        notif.delivered_count = fcm_result["success"]
    else:
        # Degraded: FCM disabled. Count the matched devices so admins see
        # the real reach when the message lands in the in-app feed.
        notif.delivered_count = len(target_tokens)

    # Garbage-collect invalid tokens reported by FCM.
    if fcm_result["invalid"]:
        from sqlalchemy import delete as sa_delete

        await db.execute(
            sa_delete(PushToken).where(PushToken.token.in_(fcm_result["invalid"]))
        )
        log.info(
            "push.tokens_pruned",
            n=len(fcm_result["invalid"]),
            notification_id=str(notif.id),
        )

    log.info(
        "push.sent",
        title=payload.title,
        audience=payload.audience.value,
        target=len(target_tokens),
        delivered=fcm_result["success"],
        failure=fcm_result["failure"],
    )
    await db.flush()
    return notif


@router.get("/push", response_model=list[PushRead])
async def list_push(_: AdminUser, db: DbSession) -> list[PushNotification]:
    rows = (
        await db.execute(
            select(PushNotification).order_by(PushNotification.created_at.desc()).limit(100)
        )
    ).scalars().all()
    return list(rows)


@router.get("/push/status")
async def push_status(_: AdminUser, db: DbSession) -> dict:
    """Return FCM configuration + delivery stats so admins can diagnose issues."""
    from app.services import fcm

    status = fcm.status()
    tokens_count = (await db.execute(select(func.count(PushToken.id)))).scalar_one()
    audience_count = (
        await db.execute(
            select(PushAudience, func.count(PushToken.id))
            .group_by(PushAudience)
            .where(
                PushToken.user_id.in_(
                    select(User.id).where(User.is_active == True)  # noqa: E712
                )
            )
        )
    ).all()
    return {
        **status,
        "registered_tokens": tokens_count,
        "audience_breakdown": {
            "all_users": tokens_count,  # all tokens are eligible for `all`
            "course_buyers": sum(c for a, c in audience_count) if audience_count else tokens_count,
        },
        "hint": (
            "FCM sozlamalarni to'g'ri bajarish uchun docs/FCM_SETUP.md'ga qarang."
            if not status["configured"]
            else "FCM tayyor. Test yuborish uchun 'Test push' tugmasini bosing."
        ),
    }


@router.post("/push/test", response_model=PushRead)
async def test_push(payload: PushCreate, admin: AdminUser, db: DbSession) -> PushNotification:
    """Send a test push to the admin's own device tokens (or target if specified).

    Used to verify FCM is wired correctly before blasting to all users.
    """
    from app.services import fcm

    # Find tokens for this admin (or the explicit target).
    target_user_id = (
        payload.target_id
        if payload.target_id and payload.audience == PushAudience.user
        else admin.id
    )
    rows = (
        await db.execute(select(PushToken).where(PushToken.user_id == target_user_id))
    ).scalars().all()
    target_tokens = [t.token for t in rows]

    notif = PushNotification(
        title=payload.title or "Test xabar",
        body=payload.body or "NotiqAI push testi ✓",
        audience=PushAudience.user,
        target_id=target_user_id,
        sent_by=admin.id,
        sent_at=datetime.now(UTC),
        delivered_count=0,
    )
    db.add(notif)
    await db.flush()

    fcm_result = await fcm.send_to_tokens(
        target_tokens,
        title=notif.title,
        body=notif.body,
        data={"notification_id": str(notif.id), "test": "1"},
    )
    if fcm_result["success"] or fcm_result["failure"]:
        notif.delivered_count = fcm_result["success"]
    else:
        notif.delivered_count = len(target_tokens)
    if fcm_result["invalid"]:
        from sqlalchemy import delete as sa_delete

        await db.execute(
            sa_delete(PushToken).where(PushToken.token.in_(fcm_result["invalid"]))
        )
    await db.flush()
    return notif


# ───────────────────── Courses (video darsliklar) ─────────────────────

@router.get("/courses", response_model=list[dict])
async def list_courses_admin(_: CuratorUser, db: DbSession) -> list[dict]:
    rows = (
        await db.execute(
            select(Course).options(selectinload(Course.lessons)).order_by(Course.created_at.desc())
        )
    ).scalars().all()
    return [
        {
            "id": str(c.id),
            "title": c.title,
            "slug": c.slug,
            "description": c.description,
            "cover_url": c.cover_url,
            "price": str(c.price),
            "level": c.level,
            "is_published": c.is_published,
            "lesson_count": len(c.lessons),
        }
        for c in rows
    ]


@router.post("/courses", status_code=201)
async def create_course(
    payload: dict,
    _: CuratorUser,
    db: DbSession,
) -> dict:
    title = (payload.get("title") or "").strip()
    if not title:
        raise AppError("Kurs nomi kiritilishi shart.", status_code=400)
    slug_base = slugify(title)
    slug = slug_base
    idx = 1
    while (await db.execute(select(Course).where(Course.slug == slug))).scalar_one_or_none():
        slug = f"{slug_base}-{idx}"
        idx += 1
    course = Course(
        title=title,
        slug=slug,
        description=payload.get("description"),
        price=float(payload.get("price", 0)),
        level=payload.get("level", "beginner"),
        is_published=False,
    )
    db.add(course)
    await db.flush()
    return {"id": str(course.id), "title": course.title, "slug": course.slug, "is_published": False, "lesson_count": 0}


@router.get("/courses/{course_id}")
async def get_course_admin(course_id: uuid.UUID, _: CuratorUser, db: DbSession) -> dict:
    course = (
        await db.execute(
            select(Course)
            .where(Course.id == course_id)
            .options(selectinload(Course.lessons).selectinload(Lesson.questions))
        )
    ).scalar_one_or_none()
    if course is None:
        raise NotFoundError("Kurs topilmadi.")
    return {
        "id": str(course.id),
        "title": course.title,
        "slug": course.slug,
        "description": course.description,
        "cover_url": course.cover_url,
        "price": str(course.price),
        "level": course.level,
        "is_published": course.is_published,
        "lesson_count": len(course.lessons),
        "lessons": [
            {
                "id": str(l.id),
                "title": l.title,
                "description": l.description,
                "order_index": l.order_index,
                "video_url": l.video_url,
                "duration_sec": l.duration_sec,
                "is_voice_exercise": l.is_voice_exercise,
                "voice_exercise_prompt": l.voice_exercise_prompt,
                "questions": [
                    {
                        "id": str(q.id),
                        "question": q.question,
                        "options": q.options,
                        "correct_index": q.correct_index,
                        "order_index": q.order_index,
                    }
                    for q in sorted(l.questions, key=lambda x: x.order_index)
                ],
            }
            for l in sorted(course.lessons, key=lambda x: x.order_index)
        ],
    }


@router.patch("/courses/{course_id}")
async def update_course(course_id: uuid.UUID, payload: dict, _: CuratorUser, db: DbSession) -> dict:
    course = await db.get(Course, course_id)
    if course is None:
        raise NotFoundError("Kurs topilmadi.")
    for field in ("title", "description", "price", "level", "is_published"):
        if field in payload:
            setattr(course, field, payload[field])
    await db.flush()
    return {"id": str(course.id), "is_published": course.is_published, "title": course.title}


@router.post("/courses/{course_id}/cover")
async def upload_course_cover(
    course_id: uuid.UUID,
    _: CuratorUser,
    db: DbSession,
    file: UploadFile = File(...),
) -> dict:
    course = await db.get(Course, course_id)
    if course is None:
        raise NotFoundError("Kurs topilmadi.")
    if not (file.content_type or "").startswith("image/"):
        raise AppError("Faqat rasm fayllari qabul qilinadi (image/*).", status_code=400)
    data = await file.read()
    ext = (file.filename or "cover.jpg").rsplit(".", 1)[-1]
    url = await storage.save_bytes(
        data, f"covers/course_{course_id}.{ext}", content_type=file.content_type or "image/jpeg"
    )
    course.cover_url = url
    await db.flush()
    return {"cover_url": url}


@router.delete("/courses/{course_id}")
async def delete_course(course_id: uuid.UUID, _: CuratorUser, db: DbSession) -> dict:
    course = await db.get(Course, course_id)
    if course is None:
        raise NotFoundError("Kurs topilmadi.")
    await db.delete(course)
    return {"message": "Kurs o'chirildi."}


@router.post("/courses/{course_id}/lessons", status_code=201)
async def add_lesson(course_id: uuid.UUID, payload: dict, _: CuratorUser, db: DbSession) -> dict:
    course = await db.get(Course, course_id)
    if course is None:
        raise NotFoundError("Kurs topilmadi.")
    title = (payload.get("title") or "").strip()
    if not title:
        raise AppError("Dars nomi kiritilishi shart.", status_code=400)
    max_order = (
        await db.execute(
            select(func.coalesce(func.max(Lesson.order_index), -1)).where(Lesson.course_id == course_id)
        )
    ).scalar_one()
    lesson = Lesson(
        course_id=course_id,
        title=title,
        description=payload.get("description"),
        order_index=max_order + 1,
        is_voice_exercise=bool(payload.get("is_voice_exercise", False)),
        voice_exercise_prompt=payload.get("voice_exercise_prompt"),
    )
    db.add(lesson)
    await db.flush()
    return {"id": str(lesson.id), "title": lesson.title, "order_index": lesson.order_index, "video_url": None}


@router.post("/lessons/{lesson_id}/video")
async def upload_lesson_video(
    lesson_id: uuid.UUID,
    _: CuratorUser,
    db: DbSession,
    file: UploadFile = File(...),
) -> dict:
    lesson = await db.get(Lesson, lesson_id)
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")
    if not (file.content_type or "").startswith("video/"):
        raise AppError("Faqat video fayllari qabul qilinadi (video/*).", status_code=400)
    data = await file.read()
    ext = (file.filename or "video.mp4").rsplit(".", 1)[-1]
    url = await storage.save_bytes(
        data,
        folder="videos",
        filename=f"lesson_{lesson_id}.{ext}",
        content_type=file.content_type or "video/mp4",
    )
    lesson.video_url = url
    await db.flush()
    log.info("lesson.video_uploaded", lesson_id=str(lesson_id), url=url)
    return {"video_url": url}


@router.delete("/lessons/{lesson_id}")
async def delete_lesson(lesson_id: uuid.UUID, _: CuratorUser, db: DbSession) -> dict:
    lesson = await db.get(Lesson, lesson_id)
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")
    await db.delete(lesson)
    return {"message": "Dars o'chirildi."}


@router.patch("/lessons/{lesson_id}")
async def update_lesson(lesson_id: uuid.UUID, payload: dict, _: CuratorUser, db: DbSession) -> dict:
    lesson = await db.get(Lesson, lesson_id)
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")
    for field in ("title", "description", "is_voice_exercise", "voice_exercise_prompt"):
        if field in payload:
            setattr(lesson, field, payload[field])
    await db.flush()
    return {
        "id": str(lesson.id),
        "title": lesson.title,
        "description": lesson.description,
        "is_voice_exercise": lesson.is_voice_exercise,
        "voice_exercise_prompt": lesson.voice_exercise_prompt,
    }


@router.post("/lessons/{lesson_id}/questions", status_code=201)
async def add_lesson_question(lesson_id: uuid.UUID, payload: dict, _: CuratorUser, db: DbSession) -> dict:
    lesson = await db.get(Lesson, lesson_id)
    if lesson is None:
        raise NotFoundError("Dars topilmadi.")
    question_text = (payload.get("question") or "").strip()
    options = payload.get("options") or []
    correct_index = int(payload.get("correct_index", 0))
    if not question_text:
        raise AppError("Savol matni kiritilishi shart.", status_code=400)
    if len(options) < 2:
        raise AppError("Kamida 2 ta javob varianti kiritilishi shart.", status_code=400)
    max_order = (
        await db.execute(
            select(func.coalesce(func.max(LessonQuestion.order_index), -1))
            .where(LessonQuestion.lesson_id == lesson_id)
        )
    ).scalar_one()
    q = LessonQuestion(
        lesson_id=lesson_id,
        question=question_text,
        options=options,
        correct_index=correct_index,
        order_index=max_order + 1,
    )
    db.add(q)
    await db.flush()
    return {
        "id": str(q.id),
        "question": q.question,
        "options": q.options,
        "correct_index": q.correct_index,
        "order_index": q.order_index,
    }


@router.delete("/lessons/{lesson_id}/questions/{question_id}")
async def delete_lesson_question(
    lesson_id: uuid.UUID, question_id: uuid.UUID, _: CuratorUser, db: DbSession
) -> dict:
    q = await db.get(LessonQuestion, question_id)
    if q is None or q.lesson_id != lesson_id:
        raise NotFoundError("Savol topilmadi.")
    await db.delete(q)
    return {"message": "Savol o'chirildi."}


# ───────────────────── Curator management (admin only) ─────────────────────

@router.get("/curators", response_model=list[CuratorRead])
async def list_curators(_: AdminUser, db: DbSession) -> list[User]:
    """List all staff members with the curator role."""
    rows = (
        await db.execute(
            select(User)
            .where(User.role == Role.curator)
            .order_by(User.created_at.desc())
        )
    ).scalars().all()
    return list(rows)


@router.post("/curators", response_model=CuratorRead, status_code=201)
async def create_curator(
    payload: CuratorCreate, _: AdminUser, db: DbSession
) -> User:
    """Create a new curator with email/password login."""
    email = payload.email.lower()
    exists = (
        await db.execute(
            select(AuthIdentity).where(
                AuthIdentity.provider == AuthProvider.password,
                AuthIdentity.provider_uid == email,
            )
        )
    ).scalar_one_or_none()
    if exists is not None:
        raise ConflictError("Bu email bilan kurator allaqachon mavjud.")

    user = User(
        full_name=payload.full_name,
        email=email,
        role=Role.curator,
        is_verified=True,
        is_active=True,
    )
    db.add(user)
    await db.flush()
    db.add(
        AuthIdentity(
            user_id=user.id,
            provider=AuthProvider.password,
            provider_uid=email,
            password_hash=hash_password(payload.password),
        )
    )
    await db.flush()
    log.info("curator.created", curator_id=str(user.id), email=email)
    return user


@router.patch("/curators/{curator_id}", response_model=CuratorRead)
async def update_curator(
    curator_id: uuid.UUID,
    payload: CuratorUpdate,
    _: AdminUser,
    db: DbSession,
) -> User:
    """Update curator profile / password / active state."""
    user = await db.get(User, curator_id)
    if user is None or user.role != Role.curator:
        raise NotFoundError("Kurator topilmadi.")

    if payload.full_name is not None:
        user.full_name = payload.full_name
    if payload.is_active is not None:
        user.is_active = payload.is_active
    if payload.password is not None:
        identity = (
            await db.execute(
                select(AuthIdentity).where(
                    AuthIdentity.user_id == user.id,
                    AuthIdentity.provider == AuthProvider.password,
                )
            )
        ).scalar_one_or_none()
        if identity is None:
            raise NotFoundError("Kuratorning login ma'lumotlari topilmadi.")
        identity.password_hash = hash_password(payload.password)

    await db.flush()
    log.info("curator.updated", curator_id=str(curator_id))
    return user


# ───────────────────── Pronunciation References (curator) ─────────────────────

@router.get("/references", response_model=list[dict])
async def list_references_admin(
    _: CuratorUser, db: DbSession
) -> list[dict]:
    rows = (
        await db.execute(
            select(PronunciationReference).order_by(PronunciationReference.created_at)
        )
    ).scalars().all()
    return [
        {
            "id": str(r.id),
            "title": r.title,
            "text": r.text,
            "reference_audio_url": r.reference_audio_url,
            "language": r.language,
            "difficulty": r.difficulty,
            "created_at": r.created_at.isoformat(),
        }
        for r in rows
    ]


@router.post("/references", status_code=201)
async def create_reference(
    _: CuratorUser,
    db: DbSession,
    title: str = Form(...),
    text: str = Form(...),
    difficulty: str = Form("easy"),
    language: str = Form("uz"),
    audio: UploadFile | None = File(None),
) -> dict:
    ref = PronunciationReference(
        title=title.strip(),
        text=text.strip(),
        difficulty=difficulty,
        language=language,
    )
    if audio is not None:
        content_type = audio.content_type or ""
        if not content_type.startswith("audio/"):
            raise AppError("Faqat audio fayllari qabul qilinadi (audio/*).", status_code=400)
        data = await audio.read()
        if data:
            url = await storage.save_bytes(
                data,
                folder="references",
                filename=audio.filename or "reference.m4a",
                content_type=content_type,
            )
            ref.reference_audio_url = url
            log.info("reference.audio_uploaded", title=title, url=url)
    db.add(ref)
    await db.flush()
    return {
        "id": str(ref.id),
        "title": ref.title,
        "text": ref.text,
        "reference_audio_url": ref.reference_audio_url,
        "language": ref.language,
        "difficulty": ref.difficulty,
    }


@router.patch("/references/{ref_id}")
async def update_reference(
    ref_id: uuid.UUID,
    payload: dict,
    _: CuratorUser,
    db: DbSession,
) -> dict:
    ref = await db.get(PronunciationReference, ref_id)
    if ref is None:
        raise NotFoundError("Matn topilmadi.")
    for field_name in ("title", "text", "difficulty", "language"):
        if field_name in payload:
            setattr(ref, field_name, payload[field_name])
    await db.flush()
    return {
        "id": str(ref.id),
        "title": ref.title,
        "text": ref.text,
        "reference_audio_url": ref.reference_audio_url,
        "language": ref.language,
        "difficulty": ref.difficulty,
    }


@router.post("/references/{ref_id}/audio")
async def upload_reference_audio(
    ref_id: uuid.UUID,
    _: CuratorUser,
    db: DbSession,
    file: UploadFile = File(...),
) -> dict:
    """Upload or replace the expert reference audio for a pronunciation text."""
    ref = await db.get(PronunciationReference, ref_id)
    if ref is None:
        raise NotFoundError("Matn topilmadi.")
    content_type = file.content_type or ""
    if not content_type.startswith("audio/"):
        raise AppError("Faqat audio fayllari qabul qilinadi (audio/*).", status_code=400)
    data = await file.read()
    if not data:
        raise AppError("Audio fayl bo'sh.", status_code=400)
    url = await storage.save_bytes(
        data,
        folder="references",
        filename=file.filename or "reference.m4a",
        content_type=content_type,
    )
    ref.reference_audio_url = url
    await db.flush()
    log.info("reference.audio_uploaded", ref_id=str(ref_id), url=url)
    return {"reference_audio_url": url}


@router.delete("/references/{ref_id}", response_model=Message)
async def delete_reference(
    ref_id: uuid.UUID, _: CuratorUser, db: DbSession
) -> Message:
    ref = await db.get(PronunciationReference, ref_id)
    if ref is None:
        raise NotFoundError("Matn topilmadi.")
    await db.delete(ref)
    await db.flush()
    log.info("reference.deleted", ref_id=str(ref_id))
    return Message(message="Matn o'chirildi.")


@router.delete("/curators/{curator_id}", response_model=Message)
async def delete_curator(
    curator_id: uuid.UUID,
    _: AdminUser,
    db: DbSession,
    force: bool = Query(default=False, description="Permanently delete instead of deactivating"),
) -> Message:
    """Deactivate (soft-delete) or permanently delete a curator.

    ``?force=true`` performs a hard delete — the row is removed from the
    database.  FK columns that reference this user are set to NULL by the
    database (``ondelete="SET NULL"``), so historical data remains intact.
    Without the flag the curator is only deactivated (``is_active=False``).
    """
    user = await db.get(User, curator_id)
    if user is None or user.role != Role.curator:
        raise NotFoundError("Kurator topilmadi.")

    if force:
        await db.delete(user)
        await db.flush()
        log.info("curator.deleted", curator_id=str(curator_id))
        return Message(message="Kurator o'chirildi.")

    user.is_active = False
    await db.flush()
    log.info("curator.deactivated", curator_id=str(curator_id))
    return Message(message="Kurator bloklandi.")
