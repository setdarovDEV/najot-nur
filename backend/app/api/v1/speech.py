"""Speech (free-form) and voice (read-aloud) analysis endpoints.

Anonymous users can browse reference texts AND run analyses.  Results are only
persisted to the database when the request carries a valid auth token.
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import UTC, datetime
from types import SimpleNamespace

from fastapi import APIRouter, File, Form, UploadFile
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession, OptionalUser
from app.core.config import settings
from app.core.exceptions import AppError, NotFoundError
from app.core.logging import get_logger
from app.models.analysis import PronunciationReference, SpeechAnalysis, VoiceAnalysis
from app.models.enums import AnalysisStatus
from app.schemas.speech import (
    PronunciationReferenceRead,
    SpeechAnalysisRead,
    SpeechAnalyzeRequest,
    VoiceAnalysisRead,
    VoiceAnalyzeRequest,
)
from app.services import storage
from app.services.ai import analyze_speech, analyze_voice, transcribe

log = get_logger("speech")

router = APIRouter()

_ALLOWED_STT_LANGS = {"uz", "ru", "en"}


async def _read_audio(file: UploadFile) -> tuple[bytes, str]:
    """Validate an uploaded audio file and return ``(bytes, content_type)``."""
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
    return data, content_type


async def _transcribe_or_400(
    data: bytes, filename: str, content_type: str, language: str
) -> dict:
    if not settings.stt_enabled:
        raise AppError(
            "Server tomonida STT sozlanmagan. STT_PROVIDER=groq va GROQ_API_KEY ni "
            "o'rnating yoki transkripsiyani mijozdan yuboring (/speech/analyze).",
            status_code=503,
        )
    result = await transcribe(
        data=data, filename=filename, content_type=content_type, language=language
    )
    if result is None or not result.get("text"):
        raise AppError(
            "Nutqni matnga o'girib bo'lmadi. Audioni qayta yozing.", status_code=502
        )
    return result


def _resolve_lang(language: str | None) -> str:
    lang = (language or settings.stt_language).lower()
    return lang if lang in _ALLOWED_STT_LANGS else settings.stt_language


# ───────────────────── Reference texts (public) ─────────────────────
@router.get("/references", response_model=list[PronunciationReferenceRead])
async def list_references(db: DbSession) -> list[PronunciationReference]:
    rows = (
        await db.execute(
            select(PronunciationReference).order_by(PronunciationReference.created_at)
        )
    ).scalars().all()
    return list(rows)


# ───────────────────── Free-form speech ─────────────────────
@router.post("/analyze", response_model=SpeechAnalysisRead)
async def analyze_speech_endpoint(
    payload: SpeechAnalyzeRequest, user: CurrentUser, db: DbSession
) -> SpeechAnalysis:
    result = await analyze_speech(payload.transcript, payload.duration_sec)
    analysis = SpeechAnalysis(
        user_id=user.id,
        audio_url=payload.audio_url,
        transcript=payload.transcript,
        duration_sec=payload.duration_sec,
        status=AnalysisStatus.done,
        **result,
    )
    db.add(analysis)
    await db.flush()
    return analysis


@router.post("/free-talk", response_model=SpeechAnalysisRead)
async def free_talk_audio(
    user: OptionalUser,
    db: DbSession,
    file: UploadFile = File(...),
    language: str | None = Form(None),
) -> SpeechAnalysis | SimpleNamespace:
    """Free-form speech from an audio file: STT (Groq) → analysis (TZ §3.1/§4.2).

    Works for both authenticated and anonymous users.  Results are only saved
    to the database when a valid token is present.
    """
    data, content_type = await _read_audio(file)
    stt = await _transcribe_or_400(
        data, file.filename or "speech.webm", content_type, _resolve_lang(language)
    )
    audio_url = await storage.save_bytes(
        data, folder="speech", filename=file.filename or "speech.webm",
        content_type=content_type,
    )
    duration = int(round(stt.get("duration") or 0))
    result = await analyze_speech(stt["text"], duration)

    if user is not None:
        analysis = SpeechAnalysis(
            user_id=user.id,
            audio_url=audio_url,
            transcript=stt["text"],
            duration_sec=duration,
            status=AnalysisStatus.done,
            **result,
        )
        db.add(analysis)
        await db.flush()
        return analysis

    # Anonymous: return result without persisting
    return SimpleNamespace(
        id=uuid.uuid4(),
        status=AnalysisStatus.done,
        transcript=stt["text"],
        duration_sec=duration,
        audio_url=audio_url,
        created_at=datetime.now(UTC),
        **result,
    )


@router.get("/history", response_model=list[SpeechAnalysisRead])
async def speech_history(user: CurrentUser, db: DbSession) -> list[SpeechAnalysis]:
    rows = (
        await db.execute(
            select(SpeechAnalysis)
            .where(SpeechAnalysis.user_id == user.id)
            .order_by(SpeechAnalysis.created_at.desc())
        )
    ).scalars().all()
    return list(rows)


@router.get("/{analysis_id}", response_model=SpeechAnalysisRead)
async def get_speech(
    analysis_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> SpeechAnalysis:
    obj = await db.get(SpeechAnalysis, analysis_id)
    if obj is None or obj.user_id != user.id:
        raise NotFoundError("Tahlil topilmadi.")
    return obj


# ───────────────────── Voice (read reference) ─────────────────────
@router.post("/voice/analyze", response_model=VoiceAnalysisRead)
async def analyze_voice_endpoint(
    payload: VoiceAnalyzeRequest, user: CurrentUser, db: DbSession
) -> VoiceAnalysis:
    result = await analyze_voice(payload.reference_text, payload.transcript)
    analysis = VoiceAnalysis(
        user_id=user.id,
        reference_id=payload.reference_id,
        reference_text=payload.reference_text,
        audio_url=payload.audio_url,
        transcript=payload.transcript,
        status=AnalysisStatus.done,
        **result,
    )
    db.add(analysis)
    await db.flush()
    return analysis


@router.post("/voice/analyze-audio", response_model=VoiceAnalysisRead)
async def analyze_voice_audio(
    user: OptionalUser,
    db: DbSession,
    file: UploadFile = File(...),
    reference_text: str = Form(..., min_length=1),
    reference_id: uuid.UUID | None = Form(None),
    language: str | None = Form(None),
) -> VoiceAnalysis | SimpleNamespace:
    """Read-aloud pronunciation test from an audio file (TZ §4.2).

    Works for authenticated and anonymous users.  When a reference record has an
    expert audio URL, that audio is also transcribed and its word timings are
    passed to the analyser for pace/rhythm comparison.
    """
    data, content_type = await _read_audio(file)
    lang = _resolve_lang(language)
    stt = await _transcribe_or_400(
        data, file.filename or "voice.webm", content_type, lang
    )
    audio_url = await storage.save_bytes(
        data, folder="voice", filename=file.filename or "voice.webm",
        content_type=content_type,
    )

    # Load expert reference audio and transcribe it for timing comparison.
    reference_timings: list[dict] | None = None
    if reference_id is not None:
        ref_obj = await db.get(PronunciationReference, reference_id)
        if ref_obj is not None and ref_obj.reference_audio_url:
            ref_bytes = await storage.load_bytes(ref_obj.reference_audio_url)
            if ref_bytes:
                ref_stt = await transcribe(
                    data=ref_bytes,
                    filename="reference.m4a",
                    content_type="audio/mp4",
                    language=lang,
                )
                if ref_stt and ref_stt.get("words"):
                    reference_timings = ref_stt["words"]
                    log.info(
                        "speech.reference_transcribed",
                        reference_id=str(reference_id),
                        word_count=len(reference_timings),
                    )

    result = await analyze_voice(
        reference_text,
        stt["text"],
        stt.get("words"),
        reference_timings=reference_timings,
    )

    if user is not None:
        analysis = VoiceAnalysis(
            user_id=user.id,
            reference_id=reference_id,
            reference_text=reference_text,
            audio_url=audio_url,
            transcript=stt["text"],
            status=AnalysisStatus.done,
            **result,
        )
        db.add(analysis)
        await db.flush()
        return analysis

    # Anonymous: return result without persisting
    return SimpleNamespace(
        id=uuid.uuid4(),
        status=AnalysisStatus.done,
        reference_text=reference_text,
        transcript=stt["text"],
        audio_url=audio_url,
        created_at=datetime.now(UTC),
        **result,
    )


@router.get("/voice/{analysis_id}", response_model=VoiceAnalysisRead)
async def get_voice(
    analysis_id: uuid.UUID, user: CurrentUser, db: DbSession
) -> VoiceAnalysis:
    obj = await db.get(VoiceAnalysis, analysis_id)
    if obj is None or obj.user_id != user.id:
        raise NotFoundError("Tahlil topilmadi.")
    return obj


_PRACTICE_SYSTEM = (
    "Siz O'zbek tili talaffuz murabbiysiz. Foydalanuvchi berilgan matnni "
    "ovoz chiqarib o'qiydi va AI talaffuzini baholaydi. "
    "Iltimos, berilgan qiyinlik darajasiga mos, mazmunan qiziqarli, "
    "grammatik to'g'ri O'ZBEK tilidagi mashq matnini yozing. "
    "Matn odatiy so'zlashuv uslubida, notiqlik yoki siyosat mavzusida bo'lsin."
)

_PRACTICE_SCHEMA = {
    "type": "object",
    "properties": {
        "text": {"type": "string", "description": "O'qish uchun mashq matni"},
        "title": {"type": "string", "description": "Matn sarlavhasi (qisqa)"},
        "word_count": {"type": "integer"},
    },
    "required": ["text", "title"],
}

_PRACTICE_FALLBACKS = {
    "easy": [
        "Salom, mening ismim Ali. Men Toshkentda yashayman. Har kuni ertalab yuguraman va kitob o'qiyman. Kelajakda yaxshi notiq bo'lishni xohlayman.",
        "Bugun ob-havo juda chiroyli. Ko'cha bo'ylab yurganda daraxtlarning shitirlashini eshitdim. Tabiat menga ilhom beradi.",
    ],
    "medium": [
        "Notiqlik san'ati — bu faqat so'z aytish emas, balki fikrni aniq va ta'sirchan yetkazish mahoratidir. Har bir nutq tinglovchi qalbida iz qoldirishi kerak.",
        "Muvaffaqiyatga erishish uchun qat'iyat va sabr zarur. Har bir qiyinchilik — bu yangi imkoniyat eshigini ochadi. Biz har kuni o'zimizni takomillashtira olamiz.",
    ],
    "hard": [
        "O'zbekiston — qadimiy tarix va zamonaviy taraqqiyot kesishgan o'lka. Buyuk ipak yo'li bu zamindan o'tib, sharq va g'arbni birlashtirgan. Bugungi avlod o'sha merosni davom ettirib, jahon sahnasida munosib o'rin egallaydi.",
        "Raqamli iqtisodiyot va sun'iy intellekt texnologiyalari zamonaviy jamiyatni tubdan o'zgartirib yubormoqda. Ushbu o'zgarishlarga moslashish va ulardan samarali foydalanish — bizning asosiy vazifamizdir.",
    ],
}

import random as _random

from app.services.ai.client import structured_completion as _structured_completion


@router.post("/practice/generate")
async def generate_practice_text(
    difficulty: str = Form("medium"),
    user: CurrentUser = None,
    db: DbSession = None,
) -> dict:
    """Generate an AI practice reading text by difficulty (easy|medium|hard)."""
    if difficulty not in ("easy", "medium", "hard"):
        difficulty = "medium"

    word_targets = {"easy": "20-35", "medium": "40-60", "hard": "65-90"}
    result = await _structured_completion(
        system=_PRACTICE_SYSTEM,
        user=(
            f"Qiyinlik darajasi: {difficulty}. "
            f"So'zlar soni: taxminan {word_targets[difficulty]}. "
            "Notiqlik, o'z-o'zini taqdim etish yoki motivatsiya mavzusida matn yozing."
        ),
        tool_name="generate_practice_text",
        tool_description="Talaffuz mashqi uchun matn yaratish",
        input_schema=_PRACTICE_SCHEMA,
        max_tokens=600,
    )

    if result and result.get("text"):
        return {"text": result["text"], "title": result.get("title", "Mashq matni"), "difficulty": difficulty}

    fallback = _random.choice(_PRACTICE_FALLBACKS[difficulty])
    return {"text": fallback, "title": "Mashq matni", "difficulty": difficulty}
