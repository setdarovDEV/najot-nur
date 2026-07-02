"""Free-form speech analysis (the ~2-minute self-introduction task).

Combines a deterministic pass (filler-word counting, length/pace heuristics —
works fully offline) with a Groq deep-analysis pass that scores meaning delivery
and writes human-readable feedback in Uzbek.
"""
from __future__ import annotations

import re

from app.services.ai.client import groq_completion, structured_completion

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
~2 daqiqa gapirdi. HAQIQIY va CHUQUR tahlil qiling.

BAHOLASH MEZONLARI (0–100):

1. meaning_score — Ma'no va mazmun yetkazilishi:
   • Berilgan savollar qanchalik to'liq yoritilgan? (har bir savol +15 ball)
   • Fikrlar mantiqiy, izchil va tushunarli tartibda keltirilganmi?
   • Aniq misollar, raqamlar, faktlar bormi?
   • 0–30: Deyarli hech narsa aytilmagan yoki mavzudan chetga chiqilgan
   • 31–55: Ba'zi savollar yoritilgan, lekin yuzaki
   • 56–75: Ko'p savollar yoritilgan, aniq fikrlar bor
   • 76–90: Deyarli barcha savollar to'liq, mazmunli yoritilgan
   • 91–100: Barcha savollar mukammal, misollar va faktlar bilan

2. fluency_score — Ravonlik va nutq sifati:
   • Parazit so'zlar (aaa, mmm, yani, haligi, shu, demak) qanchalik ko'p?
   • Gaplar tugallangan, to'xtash va takrorlashlar ozmi?
   • Nutq tezligi va ritmi tabiiy va barqarormi?
   • 0–30: Juda ko'p parazit so'zlar (15+), gaplar tugallanmagan
   • 31–55: Ko'p parazit so'zlar (8-15), tez-tez to'xtashlar
   • 56–75: O'rtacha parazit so'zlar (3-7), asosan ravon
   • 76–90: Kam parazit so'zlar (1-2), asosan silliq
   • 91–100: Parazit so'zsiz, to'liq ravon va barqaror

3. overall_score — Umumiy baho (ikki mezonning og'irlik o'rtachasi):
   • overall = round(meaning_score * 0.55 + fluency_score * 0.45)
   • Lekin sub'ektiv ta'surot ham hisobga oling

MUHIM QOIDALAR:
• Har bir foydalanuvchiga UNING MATNIGA mos ball bering — standart 78 bermang!
• Bo'sh yoki juda qisqa matn (20 so'zdan kam) → overall_score: 10–20
• Faqat parazit so'zlar bo'lsa → fluency_score: 15–30
• Aniq va to'liq nutq bo'lsa → 80+ bering
• Strengths va improvements KONKRET bo'lsin, umumiy gaplar yozmang
• Barcha matn O'ZBEK tilida bo'lsin
• Faqat so'rangan JSON formatini qaytaring, boshqa narsa yozmang"""

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
        "filler_analysis": {"type": "string"},
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


def _build_filler_detail(fillers: dict[str, int]) -> str:
    if not fillers:
        return "Parazit so'zlar aniqlanmadi."
    parts = [f"'{k}' — {v} marta" for k, v in sorted(fillers.items(), key=lambda x: -x[1])]
    return "Aniqlangan parazit so'zlar: " + ", ".join(parts) + "."


async def analyze_speech(
    transcript: str, duration_sec: int = 0
) -> dict:
    """Return a dict matching SpeechAnalysis fields."""
    fillers = _count_fillers(transcript)
    total_fillers = sum(fillers.values())
    words = _word_count(transcript)
    wpm = round(words / (duration_sec / 60), 1) if duration_sec else None
    balance = _info_balance(words)
    filler_detail = _build_filler_detail(fillers)

    questions_str = "\n".join(f"  {i+1}. {q}" for i, q in enumerate(SELF_INTRO_QUESTIONS))

    wpm_str = str(wpm) if wpm else "noma'lum"
    balance_label = "yetarli" if balance == "ok" else "juda kam" if balance == "too_little" else "juda kop"
    transcript_text = transcript if transcript else "(bosh - hech narsa aytilmadi)"

    user_prompt = (
        "SAVOLLAR RO'YXATI (foydalanuvchi shu savollarni yoritishi kerak edi):\n"
        + questions_str + "\n\n"
        + "NUTQ TRANSKRIPSIYASI:\n\"\"\"\n" + transcript_text + "\n\"\"\"\n\n"
        + "STATISTIKA:\n"
        + f"  * Sozlar soni: {words}\n"
        + f"  * Davomiyligi: {duration_sec} soniya\n"
        + f"  * Sozlar/daqiqa: {wpm_str}\n"
        + f"  * Axborot hajmi: {balance} ({balance_label})\n"
        + f"  * {filler_detail}\n\n"
        + "Ushbu transkripsiyani CHUQUR tahlil qiling va HAR BIR FOYDALANUVCHIGA UNING MATNIGA MOS ball bering."
    )

    # Try Groq directly first (fast, good Uzbek understanding)
    ai = await groq_completion(
        system=_SUMMARY_SYSTEM,
        user=user_prompt,
        input_schema=_SCHEMA,
        max_tokens=1500,
        temperature=0.2,
    )

    # A structurally invalid LLM reply (missing required scores) must not 500
    # the request — treat it like a failed call and use the fallback below.
    def _valid(res: dict | None) -> bool:
        return res is not None and all(
            isinstance(res.get(k), int)
            for k in ("overall_score", "meaning_score", "fluency_score")
        ) and bool(res.get("summary"))

    if not _valid(ai):
        ai = None

    # Fall back to any configured provider
    if ai is None:
        ai = await structured_completion(
            system=_SUMMARY_SYSTEM,
            user=user_prompt,
            tool_name="record_speech_analysis",
            tool_description="Nutq tahlilini tuzilgan ko'rinishda qaytaring.",
            input_schema=_SCHEMA,
            max_tokens=1500,
            temperature=0.2,
        )
        if not _valid(ai):
            ai = None

    if ai is None:
        # Deterministic fallback — only when no AI is configured at all.
        if words < 10:
            # Empty or near-empty recording
            fluency = 5
            meaning = 5
            overall = 5
        else:
            filler_penalty = min(total_fillers * 4, 40)
            balance_penalty = 0 if balance == "ok" else 25 if balance == "too_little" else 8
            fluency = max(15, 95 - filler_penalty)
            meaning = max(10, 85 - balance_penalty - (5 if total_fillers > 10 else 0))
            overall = max(10, round(meaning * 0.55 + fluency * 0.45))
        ai = {
            "overall_score": overall,
            "meaning_score": meaning,
            "fluency_score": fluency,
            "info_balance": balance,
            "covered_questions": [],
            "missing_questions": SELF_INTRO_QUESTIONS if words < 20 else [],
            "strengths": [] if words < 20 else ["Nutq yozib olindi."],
            "improvements": (
                [f"Parazit so'zlarni kamaytiring: {filler_detail}"] if fillers else []
            ) + (
                ["Ko'proq ma'lumot bering — kamida 2 daqiqa gapiring."]
                if balance == "too_little"
                else ["Ortiqcha tafsilotlarni qisqartiring."]
                if balance == "too_much"
                else []
            ),
            "filler_analysis": filler_detail,
            "summary": (
                "Nutqingiz qabul qilindi. "
                f"{words} ta so'z, {total_fillers} ta parazit so'z aniqlandi. "
                "Matnni ravon va aniq gapirish mashqlarini davom eting!"
            ) if words >= 20 else (
                "Nutqingiz juda qisqa yoki eshitilmadi. "
                "Iltimos, 2 daqiqa davomida o'zingiz haqingizda gapiring."
            ),
        }

    return {
        "overall_score": ai["overall_score"],
        "meaning_score": ai["meaning_score"],
        "fluency_score": ai["fluency_score"],
        "filler_words": fillers,
        "pauses": [],
        "info_balance": ai.get("info_balance", balance),
        "summary": ai["summary"],
        "details": {
            "word_count": words,
            "wpm": wpm,
            "total_fillers": total_fillers,
            "filler_analysis": ai.get("filler_analysis", filler_detail),
            "covered_questions": ai.get("covered_questions", []),
            "missing_questions": ai.get("missing_questions", []),
            "strengths": ai.get("strengths", []),
            "improvements": ai.get("improvements", []),
        },
    }
