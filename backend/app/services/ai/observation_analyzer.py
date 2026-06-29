"""Observation test analysis (psychology / body-language / observation).

Scores the multiple-choice answers deterministically and asks Claude for a
qualitative read of the user's observational & psychological perception.
"""
from __future__ import annotations

from app.services.ai.client import structured_completion

_SYSTEM = (
    "Siz NotiqAI — kuzatuvchanlik va psixologiya bo'yicha murabbiysiz. "
    "Foydalanuvchi 10 ta test (psixologiya, tana tili, kuzatuvchanlik) yechdi. "
    "Uning javoblari asosida kuzatuvchanlik darajasini baholang va O'ZBEK tilida "
    "qisqa, aniq tahlil bering: kuchli tomonlari va rivojlantirish kerak "
    "bo'lgan yo'nalishlar."
)

_SCHEMA = {
    "type": "object",
    "properties": {
        "score": {"type": "integer", "minimum": 0, "maximum": 100},
        "summary": {"type": "string"},
        "strengths": {"type": "array", "items": {"type": "string"}},
        "improvements": {"type": "array", "items": {"type": "string"}},
        "by_category": {
            "type": "object",
            "properties": {
                "psychology": {"type": "string"},
                "body_language": {"type": "string"},
                "observation": {"type": "string"},
            },
        },
    },
    "required": ["score", "summary"],
}


async def analyze_observation(answers: list[dict]) -> dict:
    """`answers` items: {title, prompt, category, options, selected_option,
    correct_option, answer_text}. Returns {score, summary, analysis}."""
    gradable = [a for a in answers if a.get("correct_option") is not None]
    correct = sum(
        1 for a in gradable if a.get("selected_option") == a.get("correct_option")
    )
    base_score = round(correct / len(gradable) * 100) if gradable else None

    lines = []
    for i, a in enumerate(answers, 1):
        chosen = a.get("selected_option")
        opts = a.get("options") or []
        chosen_text = (
            opts[chosen] if isinstance(chosen, int) and 0 <= chosen < len(opts) else
            (a.get("answer_text") or "—")
        )
        lines.append(
            f"{i}. [{a.get('category')}] {a.get('title')}: javob = {chosen_text}"
        )

    ai = await structured_completion(
        system=_SYSTEM,
        user="Foydalanuvchi javoblari:\n" + "\n".join(lines),
        tool_name="record_observation_analysis",
        tool_description="Kuzatuvchanlik tahlilini tuzilgan ko'rinishda qaytaring.",
        input_schema=_SCHEMA,
    )

    if ai is None:
        score = base_score if base_score is not None else 60
        ai = {
            "score": score,
            "summary": (
                f"10 ta testdan {correct}/{len(gradable) or '—'} to'g'ri javob. "
                "Kuzatuvchanlik ko'nikmalaringizni rivojlantiring — har bir test yangi imkoniyat!"
            ),
            "strengths": [],
            "improvements": [],
            "by_category": {},
        }

    # Blend AI judgement with deterministic correctness when both exist.
    if base_score is not None:
        final_score = round(base_score * 0.6 + ai["score"] * 0.4)
    else:
        final_score = ai["score"]

    return {
        "score": final_score,
        "summary": ai["summary"],
        "analysis": {
            "correct": correct,
            "total_gradable": len(gradable),
            "strengths": ai.get("strengths", []),
            "improvements": ai.get("improvements", []),
            "by_category": ai.get("by_category", {}),
        },
    }
