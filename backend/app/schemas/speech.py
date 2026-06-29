"""Speech & voice analysis schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import AnalysisStatus


# ───── Reference texts ─────
class PronunciationReferenceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    text: str
    reference_audio_url: str | None
    language: str
    difficulty: str


# ───── Speech (free-form) ─────
class SpeechAnalyzeRequest(BaseModel):
    """When STT is done client-side, the transcript is sent directly."""

    transcript: str = Field(..., min_length=1)
    duration_sec: int = Field(0, ge=0)
    audio_url: str | None = None


class SpeechAnalysisRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    status: AnalysisStatus
    transcript: str | None
    duration_sec: int
    overall_score: int | None
    meaning_score: int | None
    fluency_score: int | None
    filler_words: dict | None
    pauses: list | None
    info_balance: str | None
    summary: str | None
    details: dict | None
    created_at: datetime


# ───── Voice (read reference text) ─────
class VoiceAnalyzeRequest(BaseModel):
    reference_id: uuid.UUID | None = None
    reference_text: str = Field(..., min_length=1)
    transcript: str = Field(..., min_length=1, description="What the user actually read")
    audio_url: str | None = None


class WordError(BaseModel):
    index: int
    word: str
    error_type: str
    note: str | None = None


# ───── Deep char-level analysis (TZ §3.5) ─────
class CharOp(BaseModel):
    position: int
    expected_char: str | None
    spoken_char: str | None
    operation: str  # match | substitute | delete | insert | transpose
    phoneme_group: str  # vowel | consonant | special
    penalty: int
    tip: str


class WordTiming(BaseModel):
    start_ms: int
    end_ms: int
    duration_ms: int


class WordAnalysis(BaseModel):
    reference_word: str
    spoken_word: str | None
    is_correct: bool
    word_score: int
    levenshtein_distance: int
    phonetic_match: float
    color: str
    ref_index: int
    timing: WordTiming | None = None
    speed_assessment: str | None = None  # sekin | normal | tez
    ai_comment: str | None = None  # per-word explanation (TZ §3.4)
    recommendation: str | None = None  # per-word practical tip
    char_ops: list[CharOp]


class VoiceAnalysisRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    status: AnalysisStatus
    reference_text: str | None
    transcript: str | None
    overall_score: int | None
    accuracy_score: int | None
    word_errors: list | None
    phoneme_errors: list | None
    word_analysis: list[WordAnalysis] | None = None
    char_stats: dict | None = None
    summary: str | None
    created_at: datetime
