"""Tests for server-side STT normalization and word-timing enrichment.

These avoid the network: ``_normalize`` and the char-level timing path are pure
functions, and ``transcribe`` short-circuits to ``None`` for the mock provider.
"""
from __future__ import annotations

import pytest

from app.services.ai import transcribe
from app.services.ai.char_analysis import (
    analyze_text_chars,
    analyze_word,
    assess_word_speed,
)
from app.services.ai.stt import _normalize


def test_normalize_verbose_json():
    raw = {
        "text": "  Salom dunyo  ",
        "duration": 1.8,
        "language": "uzbek",
        "words": [
            {"word": " Salom", "start": 0.0, "end": 0.6},
            {"word": "dunyo", "start": 0.7, "end": 1.4},
            {"word": "  ", "start": 1.4, "end": 1.4},  # blank → dropped
        ],
    }
    out = _normalize(raw)
    assert out["text"] == "Salom dunyo"
    assert out["duration"] == 1.8
    assert len(out["words"]) == 2
    assert out["words"][0] == {"word": "Salom", "start": 0.0, "end": 0.6}


@pytest.mark.asyncio
async def test_transcribe_mock_returns_none(monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "stt_provider", "mock")
    result = await transcribe(data=b"x", filename="a.webm")
    assert result is None


def test_assess_word_speed_buckets():
    # 5 chars in 1000 ms → 5 cps → slow
    assert assess_word_speed(5, 1000) == "sekin"
    # 12 chars in 1000 ms → 12 cps → normal
    assert assess_word_speed(12, 1000) == "normal"
    # 20 chars in 1000 ms → 20 cps → fast
    assert assess_word_speed(20, 1000) == "tez"
    # missing duration → no assessment
    assert assess_word_speed(5, None) is None
    assert assess_word_speed(5, 0) is None


def test_word_timing_attached_from_stt():
    wa = analyze_word("salom", "salom", timing={"start": 0.5, "end": 1.1})
    assert wa.timing == {"start_ms": 500, "end_ms": 1100, "duration_ms": 600}
    assert wa.speed_assessment in {"sekin", "normal", "tez"}


def test_timings_threaded_through_text_analysis():
    timings = [
        {"start": 0.0, "end": 0.5},
        {"start": 0.6, "end": 1.2},
    ]
    word_analyses, _ = analyze_text_chars("salom dunyo", "salom dunyo", timings)
    assert all(wa.timing is not None for wa in word_analyses)
    assert word_analyses[0].timing["duration_ms"] == 500


def test_mismatched_timings_are_ignored():
    # One timing for two words → guard kicks in, no timing attached.
    word_analyses, _ = analyze_text_chars(
        "salom dunyo", "salom dunyo", [{"start": 0.0, "end": 0.5}]
    )
    assert all(wa.timing is None for wa in word_analyses)
