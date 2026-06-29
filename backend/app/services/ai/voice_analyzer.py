"""Voice / pronunciation analysis — Groq + Gemini dual-pass engine.

Architecture
------------
The analysis runs in two concurrent AI passes on top of a fully deterministic
word/char alignment layer:

  Pass A (Groq Llama — fast):
    • Per-word summary + phoneme_errors
    • Word-level AI comments grounded in char-ops (fast, factual)

  Pass B (Gemini — rich coaching):
    • Phoneme tips per problem letter (tongue position, minimal pairs)
    • Audio exercise sentence

Both passes fire concurrently via asyncio.gather; their outputs are merged.
When only one provider is configured, that provider handles both passes.
When neither is configured the deterministic baseline is returned as-is.

Fine-tuning notes
-----------------
All prompts are written specifically for Uzbek Latin phonology:
  • Critical confusions: k↔q, g↔g', o↔o', u↔o', sh↔s, ch↔c, ng↔n
  • Stress patterns that shift meaning (oʻqimoq vs o'qi moq)
  • Temperature 0.1–0.2 → factual, low hallucination
  • Schema enforced in system prompt → valid JSON guaranteed from Groq
"""
from __future__ import annotations

import asyncio
import re
from difflib import SequenceMatcher

from app.services.ai.char_analysis import analyze_text_chars
from app.services.ai.client import gemini_completion, groq_completion, structured_completion

_TOKEN_RE = re.compile(r"[\w'ʻ']+", re.UNICODE)

# ─── Groq system prompt — concise, factual, JSON-strict ─────────────────────

_GROQ_VOICE_SYSTEM = """\
Siz O'zbek tili talaffuz tahlilchisisiz. Quyida ETALON matn va foydalanuvchi \
AYTGAN matn beriladi.

Vazifangiz:
1. Qaysi so'zlarda va qaysi TOVUSHLARDA xato bo'lganini aniqlang.
2. O'zbek tilida xarakterli tovush xatolari: k↔q, g↔g', o↔o', u↔o', sh↔s, \
ch↔c, ng↔n, h↔x. Bu xatolarni BIRINCHI navbatda tekshiring.
3. Umumiy tahlilni O'ZBEK tilida, qisqa va aniq yozing (max 3 gap).
4. Faqat so'rangan JSON formatini qaytaring, boshqa hech narsa yozmang.

Muhim: Faktlarga tayaning, o'ylab topmang."""

_GROQ_VOICE_SCHEMA = {
    "type": "object",
    "properties": {
        "phoneme_errors": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "word": {"type": "string"},
                    "sound": {"type": "string"},
                    "note": {"type": "string"},
                },
                "required": ["word", "sound", "note"],
            },
        },
        "summary": {"type": "string"},
    },
    "required": ["summary"],
}

# ─── Gemini system prompt — rich coaching ───────────────────────────────────

_GEMINI_COACHING_SYSTEM = """\
Siz NotiqAI fonetika murabbiysiz — O'zbek tilining NUTQ terapevti. \
Foydalanuvchining eng ko'p xato qilgan HARFLARI va naqshlari beriladi.

Har bir muammoli harf uchun bering:
• tip: Qanday tuzatish kerak (amaliy, juda qisqa, 1 gap)
• tongue_position: Til pozitsiyasi — anatomik, oddiy til bilan izohlang
• practice_words: O'zbek tilidagi 3–5 ta mashq so'z (oddiydan qiyinga)

Minimal juftliklar (minimal_pairs): foydalanuvchi chalkashtirayotgan tovushlar \
juftligini (masalan "qo'l – ko'l", "g'or – gor") 4–6 ta keltiring.

audio_exercise_text: Barcha muammoli harflarni o'z ichiga olgan 1 ta murakkab \
mashq gap yozing.

Barcha matn O'ZBEK tilida bo'lsin. Tilni sodda, samimiy ishlating."""

_GEMINI_COACHING_SCHEMA = {
    "type": "object",
    "properties": {
        "phoneme_tips": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "char": {"type": "string"},
                    "tip": {"type": "string"},
                    "tongue_position": {"type": "string"},
                    "practice_words": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["char", "tip", "tongue_position", "practice_words"],
            },
        },
        "minimal_pairs": {"type": "array", "items": {"type": "string"}},
        "audio_exercise_text": {"type": "string"},
    },
    "required": ["phoneme_tips"],
}

# ─── Groq word-feedback prompt ───────────────────────────────────────────────

_GROQ_WORD_SYSTEM = """\
Siz O'zbek tili talaffuz murabbiysiz. Har bir xato so'z uchun HARF OPERATSIYALARI \
beriladi (masalan: "2-pozitsiya k→q"). Faqat shu faktlarga tayaning.

Har bir so'z uchun bering:
• comment: Nima xato bo'ldi (1 gap, aniq, faktga asoslangan)
• recommendation: Qanday tuzatish kerak (1 gap, amaliy)

ref_index ni o'zgartirmang. O'ZBEK tilida yozing. Hech narsa to'qib chiqarmang."""

_GROQ_WORD_SCHEMA = {
    "type": "object",
    "properties": {
        "word_feedback": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "ref_index": {"type": "integer"},
                    "comment": {"type": "string"},
                    "recommendation": {"type": "string"},
                },
                "required": ["ref_index", "comment", "recommendation"],
            },
        }
    },
    "required": ["word_feedback"],
}

_MAX_WORD_FEEDBACK = 25


# ─── Char-level timing comparison (unchanged) ───────────────────────────────

def _tokens(text: str) -> list[str]:
    return _TOKEN_RE.findall(text)


def _norm(token: str) -> str:
    return token.lower().replace("ʻ", "'").replace("'", "'")


def align_words(reference_text: str, transcript: str) -> tuple[list[dict], int]:
    """Return (word_errors, accuracy_score 0-100).

    Deterministic SequenceMatcher alignment — runs first, no AI needed.
    """
    ref = _tokens(reference_text)
    said = _tokens(transcript)
    ref_norm = [_norm(t) for t in ref]
    said_norm = [_norm(t) for t in said]

    errors: list[dict] = []
    matcher = SequenceMatcher(None, ref_norm, said_norm, autojunk=False)
    matched = 0
    for tag, i1, i2, _j1, _j2 in matcher.get_opcodes():
        if tag == "equal":
            matched += i2 - i1
        elif tag in ("replace", "delete"):
            for idx in range(i1, i2):
                errors.append({
                    "index": idx,
                    "word": ref[idx],
                    "error_type": "mispronounced" if tag == "replace" else "missed",
                    "note": None,
                })

    accuracy = round(matched / (len(ref) or 1) * 100)
    return errors, accuracy


def _build_timing_comparison(
    spoken_timings: list[dict],
    reference_timings: list[dict],
) -> str | None:
    if not spoken_timings or not reference_timings:
        return None
    ref_tokens = [t["word"] for t in reference_timings]
    spk_tokens = [t["word"] for t in spoken_timings]
    matcher = SequenceMatcher(
        None,
        [_norm(w) for w in ref_tokens],
        [_norm(w) for w in spk_tokens],
        autojunk=False,
    )
    lines: list[str] = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag != "equal":
            continue
        for di, dj in enumerate(range(j1, j2)):
            ri = i1 + di
            ref_t = reference_timings[ri]
            spk_t = spoken_timings[dj]
            ref_dur = ref_t["end"] - ref_t["start"]
            spk_dur = spk_t["end"] - spk_t["start"]
            if ref_dur <= 0:
                continue
            ratio = spk_dur / ref_dur
            if ratio < 0.6:
                pace = "juda tez"
            elif ratio > 1.7:
                pace = "juda sekin"
            elif ratio > 1.3:
                pace = "sekinroq"
            elif ratio < 0.8:
                pace = "tezroq"
            else:
                pace = "normal"
            if pace != "normal":
                lines.append(
                    f"  '{ref_tokens[ri]}': ekspert {ref_dur:.2f}s, "
                    f"foydalanuvchi {spk_dur:.2f}s → {pace}"
                )
        if len(lines) >= 15:
            break
    if not lines:
        return None
    return "Tezlik taqqoslash (ekspert vs foydalanuvchi):\n" + "\n".join(lines)


# ─── Pass A: Groq word-level feedback ───────────────────────────────────────

async def _word_level_feedback_groq(word_analyses: list) -> None:
    """Enrich errored words with Groq LLM comments. Fast, factual, low temp."""
    errored = [wa for wa in word_analyses if not wa.is_correct][:_MAX_WORD_FEEDBACK]
    if not errored:
        return

    lines = []
    for wa in errored:
        spoken = wa.spoken_word if wa.spoken_word is not None else "(aytilmadi)"
        ops = wa.ops_summary() or "—"
        lines.append(
            f"- ref_index={wa.ref_index} | to'g'ri='{wa.reference_word}' | "
            f"aytildi='{spoken}' | ball={wa.word_score} | xatolar: {ops}"
        )

    result = await groq_completion(
        system=_GROQ_WORD_SYSTEM,
        user=(
            "Quyidagi so'zlar uchun aniq izoh va tavsiya bering:\n"
            + "\n".join(lines)
        ),
        input_schema=_GROQ_WORD_SCHEMA,
        max_tokens=2500,
        temperature=0.1,
    )
    if not result:
        # Fall back to generic structured_completion (works for gemini-only config)
        result = await structured_completion(
            system=_GROQ_WORD_SYSTEM,
            user="\n".join(lines),
            input_schema=_GROQ_WORD_SCHEMA,
            max_tokens=2500,
            temperature=0.1,
        )
    if not result:
        return

    by_index = {wa.ref_index: wa for wa in errored}
    for item in result.get("word_feedback", []):
        wa = by_index.get(item.get("ref_index"))
        if wa is None:
            continue
        if item.get("comment"):
            wa.ai_comment = item["comment"]
        if item.get("recommendation"):
            wa.recommendation = item["recommendation"]


# ─── Pass B: Gemini coaching (phoneme tips) ──────────────────────────────────

async def _char_level_tips_gemini(char_stats: dict) -> dict | None:
    """Ask Gemini for rich per-letter coaching with tongue position."""
    problem_chars = char_stats.get("top_problem_chars") or []
    patterns = char_stats.get("error_patterns") or []
    if not problem_chars:
        return None

    chars = ", ".join(f"{c['char']} ({c['count']}x)" for c in problem_chars)
    pat = (
        ", ".join(f"{p['pattern']} ({p['count']}x)" for p in patterns) or "yo'q"
    )
    groups = char_stats.get("phoneme_group_accuracy") or {}

    user_msg = (
        f"Muammoli harflar: {chars}.\n"
        f"Xato naqshlari: {pat}.\n"
        f"Fonem guruhi aniqligi (%): {groups}.\n"
        "Har bir muammoli harf uchun batafsil mashq, til pozitsiyasi va "
        "minimal juftliklarni bering."
    )

    # Try Gemini first (richer schema enforcement)
    result = await gemini_completion(
        system=_GEMINI_COACHING_SYSTEM,
        user=user_msg,
        input_schema=_GEMINI_COACHING_SCHEMA,
        max_tokens=2000,
        temperature=0.3,
    )
    if result is None:
        # Fall back to Groq if Gemini not configured
        result = await groq_completion(
            system=_GEMINI_COACHING_SYSTEM,
            user=user_msg,
            input_schema=_GEMINI_COACHING_SCHEMA,
            max_tokens=2000,
            temperature=0.2,
        )
    if result is None:
        result = await structured_completion(
            system=_GEMINI_COACHING_SYSTEM,
            user=user_msg,
            input_schema=_GEMINI_COACHING_SCHEMA,
            max_tokens=2000,
        )
    return result


# ─── Main analysis ───────────────────────────────────────────────────────────

async def analyze_voice(
    reference_text: str,
    transcript: str,
    spoken_timings: list[dict] | None = None,
    reference_timings: list[dict] | None = None,
) -> dict:
    """Full dual-pass voice analysis. Returns a dict matching VoiceAnalysis fields.

    1. Deterministic char alignment (always runs, no API needed)
    2. Pass A — Groq: word-level comments (fast, temperature=0.1)
    3. Pass B — Gemini: phoneme coaching + minimal pairs (rich)
    4. Pass C — Groq/Gemini: overall summary + phoneme_errors
    Passes A, B, C fire concurrently; only Pass 1 blocks.
    """
    # ── Step 1: deterministic ─────────────────────────────────────────────────
    word_errors, accuracy = align_words(reference_text, transcript)
    word_analyses, char_stats = analyze_text_chars(
        reference_text, transcript, spoken_timings
    )

    # Build timing block for AI prompt
    timing_block = ""
    if spoken_timings and reference_timings:
        cmp = _build_timing_comparison(spoken_timings, reference_timings)
        if cmp:
            timing_block = f"\n\n{cmp}"

    error_word_list = [e["word"] for e in word_errors] or ["yo'q"]
    ai_user_msg = (
        f"Etalon matn:\n\"\"\"\n{reference_text}\n\"\"\"\n\n"
        f"Foydalanuvchi aytgani:\n\"\"\"\n{transcript}\n\"\"\"\n\n"
        f"Aniqlangan xato so'zlar: {error_word_list}."
        f"{timing_block}"
    )

    # ── Steps 2–4: concurrent AI passes ──────────────────────────────────────
    word_feedback_task = _word_level_feedback_groq(word_analyses)

    char_tips_task = _char_level_tips_gemini(char_stats)

    # Main summary + phoneme errors — Groq (fast) then fall back
    async def _main_summary() -> dict | None:
        result = await groq_completion(
            system=_GROQ_VOICE_SYSTEM,
            user=ai_user_msg,
            input_schema=_GROQ_VOICE_SCHEMA,
            max_tokens=1200,
            temperature=0.15,
        )
        if result is None:
            result = await structured_completion(
                system=_GROQ_VOICE_SYSTEM,
                user=ai_user_msg,
                input_schema=_GROQ_VOICE_SCHEMA,
                max_tokens=1200,
            )
        return result

    _, char_tips, ai = await asyncio.gather(
        word_feedback_task,
        char_tips_task,
        _main_summary(),
    )

    # ── Merge char coaching into char_stats ───────────────────────────────────
    if char_tips:
        char_stats["phoneme_tips"] = char_tips.get("phoneme_tips", [])
        char_stats["minimal_pairs"] = char_tips.get("minimal_pairs", [])
        char_stats["audio_exercise_text"] = char_tips.get("audio_exercise_text")

    word_analysis_json = [wa.to_dict() for wa in word_analyses]

    # ── Build final summary / phoneme_errors ──────────────────────────────────
    if ai is not None:
        summary = ai.get("summary") or _fallback_summary(accuracy, word_errors)
        phoneme_errors: list = ai.get("phoneme_errors", [])
    else:
        summary = _fallback_summary(accuracy, word_errors)
        phoneme_errors = []

    overall = round(accuracy * 0.7 + (100 if not word_errors else max(50, accuracy)) * 0.3)

    return {
        "overall_score": overall,
        "accuracy_score": accuracy,
        "word_errors": word_errors,
        "phoneme_errors": phoneme_errors,
        "word_analysis": word_analysis_json,
        "char_stats": char_stats,
        "summary": summary,
    }


def _fallback_summary(accuracy: int, word_errors: list) -> str:
    """Deterministic summary when AI is unavailable."""
    if not word_errors:
        return (
            f"Ajoyib! Barcha so'zlar to'g'ri talaffuz qilindi. "
            f"Aniqlik: {accuracy}%. Mashqni davom ettiring!"
        )
    error_words = ", ".join(e["word"] for e in word_errors[:8])
    extra = f" va boshqalar" if len(word_errors) > 8 else ""
    return (
        f"Aniqlik: {accuracy}%. "
        f"Quyidagi so'zlarda xatolik: {error_words}{extra}. "
        f"Ularni alohida mashq qiling va qayta o'qib ko'ring."
    )
