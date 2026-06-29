"""Free-form speech analysis (the ~2-minute self-introduction task).

Combines a deterministic pass (filler-word counting, length/pace heuristics —
works fully offline) with an optional Claude pass that scores meaning delivery
and writes the human-readable feedback in Uzbek.
"""
from __future__ import annotations

import re

from app.services.ai.client import structured_completion

# The guided questions the speaker is asked to cover.
SELF_INTRO_QUESTIONS: list[str] = [
    "Ismingiz nima?",
    "Qayerdansiz?",
    "Qayerda o'qigansiz?",
    "Yutuqlaringiz qanday?",
    "Yaqinlaringiz haqida",
    "Asosiy maqsadingiz nima?",
]

# Common Uzbek filler / hesitation words and sounds.
FILLER_PATTERNS: dict[str, str] = {
    "hmm": r"\bh+m+\b",
    "mmm": r"\bm{2,}\b",
    "aaa": r"\ba{2,}h?\b",
    "eee": r"\be{2,}\b",
    "uh": r"\b(uh|uf)\b",
    "haligi": r"\bhaligi\b",
    "yani": r"\b(ya'?ni)\b",
    "anaqa": r"\b(anaqa|manaqa|anaqangi)\b",
    "shu": r"\bshu+\b",
    "xullas": r"\bxullas\b",
    "demak": r"\bdemak\b",
}

_SUMMARY_SYSTEM = """\
Siz NotiqAI — O'zbek nutq mahorati murabbiysiz. Foydalanuvchi o'zi haqida \
~2 daqiqa gapirdi. Quyidagi mezonlar bo'yicha baholang:

1. Ma'no yetkazilishi (meaning_score): Savollar qanchalik to'liq yoritilgan?
2. Ravonlik (fluency_score): Gapirish tezligi, parazit so'zlar, to'xtashlar.
3. Umumiy ball (overall_score): Ikki mezonning o'rtacha, lekin sub'ektiv baho.

Baholar 0–100. Barcha matn O'ZBEK tilida, aniq va rag'batlantiruvchi bo'lsin. \
Faqat so'rangan JSON formatini qaytaring."""

_SCHEMA = {
    "type": "object",
    "properties": {
        "overall_score": {"type": "integer", "minimum": 0, "maximum": 100},
        "meaning_score": {"type": "integer", "minimum": 0, "maximum": 100},
        "fluency_score": {"type": "integer", "minimum": 0, "maximum": 100},
        "info_balance": {
            "type": "string",
            "enum": ["ok", "too_little", "too_much"],
        },
        "covered_questions": {"type": "array", "items": {"type": "string"}},
        "missing_questions": {"type": "array", "items": {"type": "string"}},
        "strengths": {"type": "array", "items": {"type": "string"}},
        "improvements": {"type": "array", "items": {"type": "string"}},
        "summary": {"type": "string"},
    },
    "required": ["overall_score", "meaning_score", "fluency_score", "summary"],
}


def _count_fillers(text: str) -> dict[str, int]:
    low = text.lower()
    counts: dict[str, int] = {}
    for label, pattern in FILLER_PATTERNS.items():
        n = len(re.findall(pattern, low))
        if n:
            counts[label] = n
    return counts


def _word_count(text: str) -> int:
    return len(re.findall(r"[\w'ʻ]+", text))


def _info_balance(words: int) -> str:
    if words < 150:
        return "too_little"
    if words > 520:
        return "too_much"
    return "ok"


async def analyze_speech(
    transcript: str, duration_sec: int = 0
) -> dict:
    """Return a dict matching SpeechAnalysis fields."""
    fillers = _count_fillers(transcript)
    total_fillers = sum(fillers.values())
    words = _word_count(transcript)
    wpm = round(words / (duration_sec / 60), 1) if duration_sec else None
    balance = _info_balance(words)

    user_prompt = (
        f"Savollar ro'yxati:\n- " + "\n- ".join(SELF_INTRO_QUESTIONS) + "\n\n"
        f"Nutq matni (transkripsiya):\n\"\"\"\n{transcript}\n\"\"\"\n\n"
        f"Statistika: so'zlar={words}, davomiyligi={duration_sec}s, "
        f"parazit so'zlar={fillers or 'yo''q'}."
    )

    ai = await structured_completion(
        system=_SUMMARY_SYSTEM,
        user=user_prompt,
        tool_name="record_speech_analysis",
        tool_description="Nutq tahlilini tuzilgan ko'rinishda qaytaring.",
        input_schema=_SCHEMA,
    )

    if ai is None:
        # Deterministic fallback (no AI key configured).
        filler_penalty = min(total_fillers * 3, 30)
        balance_penalty = 0 if balance == "ok" else 12
        overall = max(40, 90 - filler_penalty - balance_penalty)
        ai = {
            "overall_score": overall,
            "meaning_score": max(45, overall - 5),
            "fluency_score": max(40, 95 - filler_penalty * 2),
            "info_balance": balance,
            "covered_questions": [],
            "missing_questions": [],
            "strengths": ["Nutq yozib olindi va tahlil qilindi."],
            "improvements": (
                [f"Parazit so'zlarni kamaytiring: {fillers}"] if fillers else []
            )
            + (
                ["Ko'proq ma'lumot bering."]
                if balance == "too_little"
                else ["Ortiqcha tafsilotlarni qisqartiring."]
                if balance == "too_much"
                else []
            ),
            "summary": (
                "Nutqingiz qabul qilindi. "
                f"{words} ta so'z, {total_fillers} ta parazit so'z aniqlandi. "
                "Matnni ravon va aniq gapirish mashqlarini davom eting — har safar yaxshilanasiz!"
            ),
        }

    return {
        "overall_score": ai["overall_score"],
        "meaning_score": ai["meaning_score"],
        "fluency_score": ai["fluency_score"],
        "filler_words": fillers,
        "pauses": [],  # requires audio-level timing; populated when STT provides it
        "info_balance": ai.get("info_balance", balance),
        "summary": ai["summary"],
        "details": {
            "word_count": words,
            "wpm": wpm,
            "total_fillers": total_fillers,
            "covered_questions": ai.get("covered_questions", []),
            "missing_questions": ai.get("missing_questions", []),
            "strengths": ai.get("strengths", []),
            "improvements": ai.get("improvements", []),
        },
    }
