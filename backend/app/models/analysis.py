"""Speech analysis, voice (pronunciation) analysis and reference texts."""
from __future__ import annotations

import uuid

from sqlalchemy import Enum, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import AnalysisStatus


class PronunciationReference(UUIDMixin, TimestampMixin, Base):
    """A pre-recorded reference text the user is asked to read aloud."""

    __tablename__ = "pronunciation_references"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    reference_audio_url: Mapped[str | None] = mapped_column(String(512))
    language: Mapped[str] = mapped_column(String(5), default="uz")
    difficulty: Mapped[str] = mapped_column(String(20), default="easy")


class SpeechAnalysis(UUIDMixin, TimestampMixin, Base):
    """Result of analysing a free-form ~2 min self-introduction recording."""

    __tablename__ = "speech_analyses"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    audio_url: Mapped[str | None] = mapped_column(String(512))
    transcript: Mapped[str | None] = mapped_column(Text)
    duration_sec: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[AnalysisStatus] = mapped_column(
        Enum(AnalysisStatus, name="analysis_status"),
        default=AnalysisStatus.pending,
        index=True,
    )
    # scores 0-100
    overall_score: Mapped[int | None] = mapped_column(Integer)
    meaning_score: Mapped[int | None] = mapped_column(Integer)
    fluency_score: Mapped[int | None] = mapped_column(Integer)
    # {"hmm": 4, "aaah": 2, "haligi": 1}
    filler_words: Mapped[dict | None] = mapped_column(JSONB)
    # [{"start": 12.3, "duration": 2.1}, ...]
    pauses: Mapped[list | None] = mapped_column(JSONB)
    info_balance: Mapped[str | None] = mapped_column(String(20))  # ok|too_little|too_much
    summary: Mapped[str | None] = mapped_column(Text)
    # structured per-question coverage, suggestions, strengths/weaknesses
    details: Mapped[dict | None] = mapped_column(JSONB)


class VoiceAnalysis(UUIDMixin, TimestampMixin, Base):
    """Result of comparing the user's reading against a reference text/audio."""

    __tablename__ = "voice_analyses"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    reference_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("pronunciation_references.id", ondelete="SET NULL")
    )
    reference_text: Mapped[str | None] = mapped_column(Text)
    audio_url: Mapped[str | None] = mapped_column(String(512))
    transcript: Mapped[str | None] = mapped_column(Text)
    status: Mapped[AnalysisStatus] = mapped_column(
        Enum(AnalysisStatus, name="analysis_status"),
        default=AnalysisStatus.pending,
        index=True,
    )
    overall_score: Mapped[int | None] = mapped_column(Integer)
    accuracy_score: Mapped[int | None] = mapped_column(Integer)
    # words to mark red in the original text:
    # [{"index": 7, "word": "ritorika", "error_type": "stress", "note": "..."}]
    word_errors: Mapped[list | None] = mapped_column(JSONB)
    # phoneme/sound level errors: [{"word":"...", "sound":"q", "note":"..."}]
    phoneme_errors: Mapped[list | None] = mapped_column(JSONB)
    # Deep char-level analysis (TZ §3.5): per-word letter operations.
    # [{"reference_word":"maktab","spoken_word":"maqtap","word_score":94,
    #   "char_ops":[{"position":2,"expected_char":"k","spoken_char":"q",...}]}]
    word_analysis: Mapped[list | None] = mapped_column(JSONB)
    # Aggregate char stats + AI letter-level coaching (TZ §3.5.7–3.5.8):
    # {"top_problem_chars":[...], "phoneme_group_accuracy":{...},
    #  "error_patterns":[...], "phoneme_tips":[...], "minimal_pairs":[...]}
    char_stats: Mapped[dict | None] = mapped_column(JSONB)
    summary: Mapped[str | None] = mapped_column(Text)
