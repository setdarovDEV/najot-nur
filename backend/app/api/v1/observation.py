"""Observation tests (10 video/image tests) and AI analysis of attempts."""
from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime

from fastapi import APIRouter
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession
from app.core.exceptions import NotFoundError
from app.core.logging import get_logger
from app.core.redis_client import cache_get, cache_set, get_redis
from app.models.observation import (
    ObservationAnswer,
    ObservationAttempt,
    ObservationTest,
)
from app.schemas.observation import (
    AiSubmitRequest,
    GenerateTestRequest,
    GeneratedSessionResponse,
    ObservationAttemptRead,
    ObservationSubmitRequest,
    ObservationTestRead,
)
from app.services.ai import analyze_observation, generate_tests

log = get_logger("observation")

# In-memory fallback for AI sessions when Redis is unavailable (dev only).
_session_store: dict[str, str] = {}

AI_SESSION_TTL = 60 * 30  # 30 minutes

router = APIRouter()


def _build_analyzer_input(
    tests: dict[uuid.UUID, ObservationTest],
    payload: ObservationSubmitRequest,
) -> list[dict]:
    items: list[dict] = []
    for ans in payload.answers:
        test = tests.get(ans.test_id)
        if test is None:
            continue
        items.append(
            {
                "title": test.title,
                "prompt": test.prompt,
                "category": test.category.value,
                "options": test.options,
                "selected_option": ans.selected_option,
                "correct_option": test.correct_option,
                "answer_text": ans.answer_text,
            }
        )
    return items


@router.get("/tests", response_model=list[ObservationTestRead])
async def list_tests(db: DbSession) -> list[ObservationTest]:
    rows = (
        await db.execute(
            select(ObservationTest)
            .where(ObservationTest.is_active.is_(True))
            .order_by(ObservationTest.order_index)
        )
    ).scalars().all()
    return list(rows)


@router.post("/submit-guest", response_model=ObservationAttemptRead)
async def submit_guest(
    payload: ObservationSubmitRequest, db: DbSession
) -> ObservationAttemptRead:
    """Run AI analysis for anonymous users without saving to the database.

    Returns the same shape as the authenticated submit endpoint so the mobile
    client can display results identically, but nothing is persisted.
    """
    test_ids = [a.test_id for a in payload.answers]
    tests = {
        t.id: t
        for t in (
            await db.execute(
                select(ObservationTest).where(ObservationTest.id.in_(test_ids))
            )
        ).scalars()
    }

    analyzer_input = _build_analyzer_input(tests, payload)
    result = await analyze_observation(analyzer_input)
    now = datetime.now(UTC)
    return ObservationAttemptRead(
        id=uuid.uuid4(),
        score=result["score"],
        summary=result["summary"],
        analysis=result["analysis"],
        completed_at=now,
        created_at=now,
    )


@router.post("/submit", response_model=ObservationAttemptRead)
async def submit(
    payload: ObservationSubmitRequest, user: CurrentUser, db: DbSession
) -> ObservationAttempt:
    test_ids = [a.test_id for a in payload.answers]
    tests = {
        t.id: t
        for t in (
            await db.execute(
                select(ObservationTest).where(ObservationTest.id.in_(test_ids))
            )
        ).scalars()
    }

    attempt = ObservationAttempt(user_id=user.id)
    db.add(attempt)
    await db.flush()

    for ans in payload.answers:
        test = tests.get(ans.test_id)
        if test is None:
            continue
        is_correct = (
            test.correct_option is not None
            and ans.selected_option == test.correct_option
        )
        db.add(
            ObservationAnswer(
                attempt_id=attempt.id,
                test_id=ans.test_id,
                selected_option=ans.selected_option,
                answer_text=ans.answer_text,
                is_correct=is_correct if test.correct_option is not None else None,
            )
        )

    analyzer_input = _build_analyzer_input(tests, payload)
    result = await analyze_observation(analyzer_input)
    attempt.score = result["score"]
    attempt.summary = result["summary"]
    attempt.analysis = result["analysis"]
    attempt.completed_at = datetime.now(UTC)
    await db.flush()
    return attempt


@router.get("/attempts", response_model=list[ObservationAttemptRead])
async def attempts(user: CurrentUser, db: DbSession) -> list[ObservationAttempt]:
    rows = (
        await db.execute(
            select(ObservationAttempt)
            .where(ObservationAttempt.user_id == user.id)
            .order_by(ObservationAttempt.created_at.desc())
        )
    ).scalars().all()
    return list(rows)


@router.post("/generate", response_model=GeneratedSessionResponse)
async def generate_ai_tests(
    payload: GenerateTestRequest, user: CurrentUser
) -> dict:
    """Generate 10 AI-based tests for an authenticated user by difficulty."""
    tests = await generate_tests(payload.difficulty)
    session_id = str(uuid.uuid4())
    data = json.dumps(tests)
    if get_redis() is not None:
        await cache_set(f"obs_session:{session_id}", data, ttl=AI_SESSION_TTL)
    else:
        _session_store[session_id] = data
    return {"session_id": session_id, "tests": tests}


@router.post("/submit-ai", response_model=ObservationAttemptRead)
async def submit_ai_tests(
    payload: AiSubmitRequest, user: CurrentUser, db: DbSession
) -> ObservationAttemptRead:
    """Submit answers for an AI-generated test session and save the attempt."""
    key = f"obs_session:{payload.session_id}"
    if get_redis() is not None:
        raw = await cache_get(key)
    else:
        raw = _session_store.get(payload.session_id)

    if not raw:
        raise NotFoundError("Test sessiyasi topilmadi yoki muddati o'tgan.")

    tests: list[dict] = json.loads(raw)
    tests_by_id = {t["id"]: t for t in tests}

    analyzer_input = []
    for ans in payload.answers:
        t = tests_by_id.get(ans.test_id)
        if t is None:
            continue
        opts = t.get("options") or []
        chosen = ans.selected_option
        analyzer_input.append(
            {
                "title": t["title"],
                "prompt": t["prompt"],
                "category": t["category"],
                "options": opts,
                "selected_option": chosen,
                "correct_option": t.get("correct_option"),
                "answer_text": None,
            }
        )

    result = await analyze_observation(analyzer_input)
    now = datetime.now(UTC)
    attempt = ObservationAttempt(
        user_id=user.id,
        score=result["score"],
        summary=result["summary"],
        analysis=result["analysis"],
        completed_at=now,
    )
    db.add(attempt)
    await db.flush()
    return ObservationAttemptRead(
        id=attempt.id,
        score=attempt.score,
        summary=attempt.summary,
        analysis=attempt.analysis,
        completed_at=attempt.completed_at,
        created_at=attempt.created_at,
    )


@router.get("/attempts/{attempt_id}", response_model=ObservationAttemptRead)
async def get_attempt(
    attempt_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> ObservationAttempt:
    obj = await db.get(ObservationAttempt, attempt_id)
    if obj is None or obj.user_id != user.id:
        raise NotFoundError("Urinish topilmadi.")
    return obj
