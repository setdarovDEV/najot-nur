"""Deep character-level pronunciation analysis (TZ §3.5).

This is NotiqAI's flagship module: for every word the speaker got wrong it
explains *which letter* was mispronounced, dropped or added, using a
Levenshtein alignment with operation back-tracking, an Uzbek phoneme map and a
per-letter penalty scheme.

Everything here is pure Python and fully deterministic — no external services,
no extra dependencies — so it works offline and is cheap to unit-test. The
optional Gemini/Claude pass (see ``voice_analyzer``) only adds prose tips on top
of these hard numbers.

Worked example from the TZ (§3.5.5): the user said ``maqtap`` instead of
``maktab``. Two substitutions (k→q at pos 2, b→p at pos 5) cost ``-3`` each, so
``word_score = 100 - 6 = 94``.
"""
from __future__ import annotations

import re
import unicodedata
from collections import Counter
from dataclasses import dataclass, field
from difflib import SequenceMatcher

# ──────────────────────────── Penalties (TZ §3.5.2) ────────────────────────────
PENALTY_SUBSTITUTE = 3
PENALTY_DELETE = 5
PENALTY_INSERT = 2
PENALTY_TRANSPOSE = 4
PENALTY_MATCH = 0

# Penalties for whole-word level outcomes (TZ §3.2.2), kept here so the word
# alignment layer shares one source of truth.
WORD_SKIPPED_PENALTY = 3
WORD_EXTRA_PENALTY = 2

# ──────────────────────── Uzbek phoneme map (TZ §3.5.3) ────────────────────────
# Multi-letter Latin graphemes that behave as a single Uzbek phoneme. They must
# be tokenised *before* single letters so "sh"/"ch"/"ng"/"o'"/"g'" stay whole.
SPECIAL_GRAPHEMES: tuple[str, ...] = ("o'", "g'", "sh", "ch", "ng")

VOWELS: frozenset[str] = frozenset({"a", "e", "i", "o", "u", "o'"})

# Letters Uzbek learners most often confuse, with a short, mouth-position tip in
# Uzbek. Keyed by a frozenset so the pair is order-independent.
_CONFUSION_TIPS: dict[frozenset[str], str] = {
    frozenset({"q", "k"}):
        "\"k\" til oldi, \"q\" uvulyar (tilning orqasi) — farqini his qiling",
    frozenset({"g'", "g"}):
        "\"g'\" orqa til sirg'aluvchi, \"g\" portlovchi — tomoqdan chiqaring",
    frozenset({"sh", "s"}):
        "\"sh\" hushtak tovushi, \"s\" sirg'aluvchi — tilni tanglayga yaqinlashtiring",
    frozenset({"ch", "s"}):
        "\"ch\" affrikat (t+sh), \"s\" sirg'aluvchi — to'liq to'sib ayting",
    frozenset({"ch", "c"}):
        "\"ch\" yagona affrikat tovush — \"c\" emas, \"ch\" deb ayting",
    frozenset({"o'", "u"}):
        "\"o'\" lablanmagan orqa unli, \"u\" lablangan — lablarni yoyib turing",
    frozenset({"o'", "o"}):
        "\"o'\" va \"o\" farqli unlilar — \"o'\" cho'ziqroq va orqaroq",
    frozenset({"x", "h"}):
        "\"x\" orqa til sirg'aluvchi, \"h\" bo'g'iz tovushi — tomoq tubidan",
    frozenset({"ng", "n"}):
        "\"ng\" tanglay burun tovushi — \"n\"+\"g\" emas, bir tovush",
}

# Voiced ↔ voiceless consonant pairs (jarangli/jarangsiz) — TZ §3.5.5 example.
_VOICING_PAIRS: dict[frozenset[str], tuple[str, str]] = {
    frozenset({"b", "p"}): ("b", "p"),
    frozenset({"d", "t"}): ("d", "t"),
    frozenset({"g", "k"}): ("g", "k"),
    frozenset({"z", "s"}): ("z", "s"),
    frozenset({"j", "sh"}): ("j", "sh"),
    frozenset({"v", "f"}): ("v", "f"),
}

# Canonical forms used to estimate *phonetic* (sound-alike) similarity: confused
# graphemes collapse to one symbol so "qalam"/"kalam" read as phonetically close.
_PHONETIC_FOLD: dict[str, str] = {
    "q": "k",
    "g'": "g",
    "x": "h",
    "o'": "o",
    "sh": "s",
    "ch": "c",
    "ng": "n",
}


def _voicing_tip(a: str, b: str) -> str | None:
    key = frozenset({a, b})
    pair = _VOICING_PAIRS.get(key)
    if pair is None:
        return None
    voiced, voiceless = pair
    return (
        f"\"{voiced}\" jarangli, \"{voiceless}\" jarangsiz — "
        "lab/tomoq titrashini his qilib ayting"
    )


def char_tip(expected: str, spoken: str | None, operation: str) -> str:
    """Human, Uzbek-language hint for a single character operation."""
    if operation == "match":
        return "To'g'ri aytildi"
    if operation == "delete":
        return f"\"{expected}\" harfi tushib qoldi — uni ayting"
    if operation == "insert":
        return f"\"{spoken}\" ortiqcha qo'shildi — uni olib tashlang"
    if operation == "transpose":
        return f"\"{expected}\" va \"{spoken}\" harflari joyi almashib ketdi"
    # substitute
    if spoken is not None:
        tip = _CONFUSION_TIPS.get(frozenset({expected, spoken}))
        if tip:
            return tip
        voicing = _voicing_tip(expected, spoken)
        if voicing:
            return voicing
    return f"\"{expected}\" o'rniga \"{spoken}\" aytildi — to'g'ri tovushni mashq qiling"


def phoneme_group(char: str) -> str:
    """Classify a grapheme as vowel / consonant / special (TZ §3.5.4)."""
    if char in VOWELS:
        return "vowel"
    if char in SPECIAL_GRAPHEMES or char in {"q", "x", "h"}:
        return "special"
    return "consonant"


# ──────────────────────────── Tokenisation ────────────────────────────
_APOSTROPHES = "ʻʼ’`"  # variants users / fonts produce for o' and g'
_WORD_RE = re.compile(r"[\w" + _APOSTROPHES + r"']+", re.UNICODE)


def normalize_word(word: str) -> str:
    """Lower-case and unify apostrophe variants so o'/oʻ/o’ compare equal."""
    word = unicodedata.normalize("NFC", word).lower()
    for ch in _APOSTROPHES:
        word = word.replace(ch, "'")
    return word


def tokenize_words(text: str) -> list[str]:
    return _WORD_RE.findall(text)


def split_graphemes(word: str) -> list[str]:
    """Split a normalized word into Uzbek graphemes (multi-letter units kept).

    e.g. "yo'lchi" → ["y", "o'", "l", "ch", "i"].
    """
    graphemes: list[str] = []
    i = 0
    n = len(word)
    while i < n:
        matched = False
        for g in SPECIAL_GRAPHEMES:
            if word.startswith(g, i):
                graphemes.append(g)
                i += len(g)
                matched = True
                break
        if not matched:
            graphemes.append(word[i])
            i += 1
    return graphemes


# ──────────────────────────── Levenshtein with back-trace ────────────────────────────
@dataclass
class CharOp:
    position: int
    expected_char: str | None
    spoken_char: str | None
    operation: str  # match | substitute | delete | insert | transpose
    phoneme_group: str
    penalty: int
    tip: str

    def to_dict(self) -> dict:
        return {
            "position": self.position,
            "expected_char": self.expected_char,
            "spoken_char": self.spoken_char,
            "operation": self.operation,
            "phoneme_group": self.phoneme_group,
            "penalty": self.penalty,
            "tip": self.tip,
        }


_Op = tuple[str, str | None, str | None]


def _edit_ops(expected: list[str], spoken: list[str]) -> list[_Op]:
    """Levenshtein alignment → ordered list of (op, expected_char, spoken_char).

    Standard DP matrix with back-tracking. Substitution / deletion / insertion
    are detected here; adjacent transpositions are collapsed in a second pass.
    """
    m, n = len(expected), len(spoken)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        dp[i][0] = i
    for j in range(1, n + 1):
        dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            cost = 0 if expected[i - 1] == spoken[j - 1] else 1
            dp[i][j] = min(
                dp[i - 1][j] + 1,       # deletion
                dp[i][j - 1] + 1,       # insertion
                dp[i - 1][j - 1] + cost,  # match / substitution
            )

    ops: list[tuple[str, str | None, str | None]] = []
    i, j = m, n
    while i > 0 or j > 0:
        diag = i > 0 and j > 0
        if diag and expected[i - 1] == spoken[j - 1] and dp[i][j] == dp[i - 1][j - 1]:
            ops.append(("match", expected[i - 1], spoken[j - 1]))
            i, j = i - 1, j - 1
        elif diag and dp[i][j] == dp[i - 1][j - 1] + 1:
            ops.append(("substitute", expected[i - 1], spoken[j - 1]))
            i, j = i - 1, j - 1
        elif i > 0 and dp[i][j] == dp[i - 1][j] + 1:
            ops.append(("delete", expected[i - 1], None))
            i -= 1
        else:
            ops.append(("insert", None, spoken[j - 1]))
            j -= 1
    ops.reverse()
    return _collapse_transpositions(ops)


def _collapse_transpositions(
    ops: list[tuple[str, str | None, str | None]],
) -> list[tuple[str, str | None, str | None]]:
    """Merge two adjacent substitutions that form a swap into one transposition.

    e.g. expected "ab" said "ba" → two subs (a→b, b→a) become one transpose.
    """
    out: list[tuple[str, str | None, str | None]] = []
    k = 0
    while k < len(ops):
        if k + 1 < len(ops):
            o1, e1, s1 = ops[k]
            o2, e2, s2 = ops[k + 1]
            if (
                o1 == "substitute"
                and o2 == "substitute"
                and e1 == s2
                and e2 == s1
                and e1 != e2
            ):
                out.append(("transpose", e1, e2))
                k += 2
                continue
        out.append(ops[k])
        k += 1
    return out


# ──────────────────────────── Phonetic similarity ────────────────────────────
def _phonetic_form(graphemes: list[str]) -> list[str]:
    return [_PHONETIC_FOLD.get(g, g) for g in graphemes]


def _levenshtein_distance(a: list[str], b: list[str]) -> int:
    m, n = len(a), len(b)
    if m == 0:
        return n
    if n == 0:
        return m
    prev = list(range(n + 1))
    for i in range(1, m + 1):
        cur = [i] + [0] * n
        for j in range(1, n + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
        prev = cur
    return prev[n]


def phonetic_match(expected: list[str], spoken: list[str]) -> float:
    """0–1 sound-alike similarity after folding confusable graphemes."""
    ef, sf = _phonetic_form(expected), _phonetic_form(spoken)
    longest = max(len(ef), len(sf)) or 1
    dist = _levenshtein_distance(ef, sf)
    return round(max(0.0, 1.0 - dist / longest), 3)


# ──────────────────────────── Word colour (TZ §3.5.6) ────────────────────────────
COLOR_GREEN = "#4CAF50"   # fully correct
COLOR_YELLOW = "#FFC107"  # 1–2 char errors
COLOR_ORANGE = "#FF9800"  # 3+ char errors
COLOR_RED = "#F44336"     # completely wrong
COLOR_GRAY = "#9E9E9E"    # extra word said


def _word_color(error_count: int, word_score: int, *, extra: bool = False) -> str:
    if extra:
        return COLOR_GRAY
    if error_count == 0:
        return COLOR_GREEN
    if word_score < 40:
        return COLOR_RED
    if error_count <= 2:
        return COLOR_YELLOW
    return COLOR_ORANGE


_PENALTY_BY_OP = {
    "match": PENALTY_MATCH,
    "substitute": PENALTY_SUBSTITUTE,
    "delete": PENALTY_DELETE,
    "insert": PENALTY_INSERT,
    "transpose": PENALTY_TRANSPOSE,
}


def assess_word_speed(n_chars: int, duration_ms: int | None) -> str | None:
    """Per-word delivery speed from its duration (TZ §3.5.4: sekin/normal/tez).

    Uses characters-per-second so longer words aren't unfairly flagged slow.
    """
    if not duration_ms or duration_ms <= 0 or n_chars <= 0:
        return None
    cps = n_chars / (duration_ms / 1000)
    if cps < 8:
        return "sekin"
    if cps > 16:
        return "tez"
    return "normal"


@dataclass
class WordAnalysis:
    reference_word: str
    spoken_word: str | None
    is_correct: bool
    word_score: int
    levenshtein_distance: int
    phonetic_match: float
    color: str
    char_ops: list[CharOp] = field(default_factory=list)
    ref_index: int = 0  # position in the reference token list (for UI highlight)
    timing: dict | None = None  # {"start_ms","end_ms","duration_ms"} from STT
    speed_assessment: str | None = None  # sekin | normal | tez
    # Per-word natural-language coaching (deterministic baseline, optionally
    # upgraded by the LLM in voice_analyzer — TZ §3.4/§3.5.8).
    ai_comment: str | None = None
    recommendation: str | None = None

    def ops_summary(self) -> str:
        """Compact, factual description of the letter errors (for AI grounding)."""
        parts: list[str] = []
        for op in self.char_ops:
            pos = op.position
            if op.operation == "substitute":
                parts.append(f"{pos}-pozitsiya: {op.expected_char}→{op.spoken_char}")
            elif op.operation == "delete":
                parts.append(f"{pos}-pozitsiya: '{op.expected_char}' tushib qoldi")
            elif op.operation == "insert":
                parts.append(f"{pos}-pozitsiya: '{op.spoken_char}' qo'shildi")
            elif op.operation == "transpose":
                parts.append(
                    f"{op.position}-pozitsiya: '{op.expected_char}'/'{op.spoken_char}' "
                    "joyi almashdi"
                )
        return "; ".join(parts)

    def to_dict(self) -> dict:
        return {
            "reference_word": self.reference_word,
            "spoken_word": self.spoken_word,
            "is_correct": self.is_correct,
            "word_score": self.word_score,
            "levenshtein_distance": self.levenshtein_distance,
            "phonetic_match": self.phonetic_match,
            "color": self.color,
            "ref_index": self.ref_index,
            "timing": self.timing,
            "speed_assessment": self.speed_assessment,
            "ai_comment": self.ai_comment,
            "recommendation": self.recommendation,
            "char_ops": [op.to_dict() for op in self.char_ops],
        }


def _build_timing(timing: dict | None) -> dict | None:
    """Turn STT ``{start, end}`` seconds into a ms timing dict."""
    if not timing:
        return None
    start = timing.get("start")
    end = timing.get("end")
    if start is None or end is None:
        return None
    start_ms = int(round(start * 1000))
    end_ms = int(round(end * 1000))
    return {
        "start_ms": start_ms,
        "end_ms": end_ms,
        "duration_ms": max(0, end_ms - start_ms),
    }


def _baseline_comment(
    reference_word: str,
    char_ops: list[CharOp],
    *,
    skipped: bool,
    is_correct: bool,
) -> tuple[str, str | None]:
    """Deterministic per-word comment + recommendation (offline baseline).

    Always returns something so every word has an explanation even without an
    LLM; the AI pass later upgrades the errored ones.
    """
    if skipped:
        return (
            f"\"{reference_word}\" so'zi umuman aytilmadi.",
            "Bu so'zni gap ichida qoldirmasdan, aniq ayting.",
        )
    if is_correct:
        return (f"\"{reference_word}\" to'g'ri va aniq aytildi.", None)

    error_ops = [op for op in char_ops if op.operation != "match"]
    tips = [op.tip for op in error_ops if op.tip]
    n = len(error_ops)
    comment = (
        f"\"{reference_word}\" so'zida {n} ta harf xatosi bor: "
        + "; ".join(tips[:3])
        + ("." if tips else "")
    )
    rec = "Shu so'zni sekin, har bir harfni alohida his qilib mashq qiling."
    return comment, rec


def analyze_word(
    reference_word: str,
    spoken_word: str | None,
    *,
    ref_index: int = 0,
    timing: dict | None = None,
) -> WordAnalysis:
    """Full character-level analysis for one reference/spoken word pair.

    ``spoken_word=None`` means the whole word was skipped (TZ "deletion" of a
    word) — every reference letter is reported as deleted. ``timing`` is the STT
    ``{start, end}`` (seconds) for the spoken word, if available.
    """
    ref_norm = normalize_word(reference_word)
    ref_chars = split_graphemes(ref_norm)
    timing_ms = _build_timing(timing)

    if spoken_word is None:
        char_ops = [
            CharOp(
                position=p,
                expected_char=c,
                spoken_char=None,
                operation="delete",
                phoneme_group=phoneme_group(c),
                penalty=PENALTY_DELETE,
                tip=char_tip(c, None, "delete"),
            )
            for p, c in enumerate(ref_chars)
        ]
        comment, rec = _baseline_comment(
            ref_norm, char_ops, skipped=True, is_correct=False
        )
        return WordAnalysis(
            reference_word=ref_norm,
            spoken_word=None,
            is_correct=False,
            word_score=0,
            levenshtein_distance=len(ref_chars),
            phonetic_match=0.0,
            color=COLOR_RED,
            char_ops=char_ops,
            ref_index=ref_index,
            timing=None,
            speed_assessment=None,
            ai_comment=comment,
            recommendation=rec,
        )

    spoken_norm = normalize_word(spoken_word)
    spoken_chars = split_graphemes(spoken_norm)

    raw_ops = _edit_ops(ref_chars, spoken_chars)

    char_ops: list[CharOp] = []
    total_penalty = 0
    error_count = 0
    position = 0  # position counts expected-side graphemes
    for op, exp_c, spk_c in raw_ops:
        penalty = _PENALTY_BY_OP[op]
        # The phoneme group is keyed on the expected letter, falling back to the
        # spoken one for pure insertions.
        group_char = exp_c if exp_c is not None else (spk_c or "")
        char_ops.append(
            CharOp(
                position=position,
                expected_char=exp_c,
                spoken_char=spk_c,
                operation=op,
                phoneme_group=phoneme_group(group_char),
                penalty=penalty,
                tip=char_tip(exp_c or "", spk_c, op),
            )
        )
        total_penalty += penalty
        if op != "match":
            error_count += 1
        if op != "insert":  # insertions don't advance the expected cursor
            position += 1

    word_score = max(0, 100 - total_penalty)
    lev = _levenshtein_distance(ref_chars, spoken_chars)
    pm = phonetic_match(ref_chars, spoken_chars)
    is_correct = error_count == 0
    speed = assess_word_speed(
        len(spoken_chars), timing_ms["duration_ms"] if timing_ms else None
    )
    comment, rec = _baseline_comment(
        ref_norm, char_ops, skipped=False, is_correct=is_correct
    )
    return WordAnalysis(
        reference_word=ref_norm,
        spoken_word=spoken_norm,
        is_correct=is_correct,
        word_score=word_score,
        levenshtein_distance=lev,
        phonetic_match=pm,
        color=_word_color(error_count, word_score),
        char_ops=char_ops,
        ref_index=ref_index,
        timing=timing_ms,
        speed_assessment=speed,
        ai_comment=comment,
        recommendation=rec,
    )


# ─────────────────── Aggregate statistics (TZ §3.5.7) ───────────────────
def build_char_stats(word_analyses: list[WordAnalysis]) -> dict:
    """Roll up per-word analyses into the progress statistics from TZ §3.5.7."""
    problem_chars: Counter[str] = Counter()
    pattern_counter: Counter[str] = Counter()
    group_errors: Counter[str] = Counter()
    group_totals: Counter[str] = Counter()

    for wa in word_analyses:
        for op in wa.char_ops:
            grp = op.phoneme_group
            group_totals[grp] += 1
            if op.operation == "match":
                continue
            if op.expected_char:
                problem_chars[op.expected_char] += 1
                group_errors[grp] += 1
            if op.operation == "substitute" and op.expected_char and op.spoken_char:
                pattern_counter[f"{op.expected_char}→{op.spoken_char}"] += 1
            elif op.operation == "transpose" and op.expected_char and op.spoken_char:
                pattern_counter[f"{op.expected_char}↔{op.spoken_char}"] += 1

    # Weakness per phoneme group as an accuracy percentage.
    group_weakness = {
        grp: round((1 - group_errors[grp] / total) * 100)
        for grp, total in group_totals.items()
        if total
    }

    hardest = sorted(
        (wa for wa in word_analyses if not wa.is_correct),
        key=lambda w: w.word_score,
    )[:5]

    return {
        "top_problem_chars": [
            {"char": c, "count": n} for c, n in problem_chars.most_common(5)
        ],
        "hardest_words": [
            {"word": wa.reference_word, "score": wa.word_score} for wa in hardest
        ],
        "phoneme_group_accuracy": group_weakness,
        "error_patterns": [
            {"pattern": p, "count": n} for p, n in pattern_counter.most_common(5)
        ],
        "total_char_errors": int(sum(problem_chars.values())),
    }


# ──────────────────────────── Text-level orchestrator ────────────────────────────
def analyze_text_chars(
    reference_text: str,
    transcript: str,
    spoken_timings: list[dict] | None = None,
) -> tuple[list[WordAnalysis], dict]:
    """Align reference vs spoken words, then run char analysis on each pair.

    Returns ``(word_analyses, char_stats)``. Only reference words are scored;
    extra spoken words are surfaced inside ``char_stats`` but not graded (they
    are shown grey in the UI, TZ §3.5.6).

    ``spoken_timings`` is an optional list of STT ``{start, end}`` dicts parallel
    to the spoken tokens; when its length matches it feeds per-word timing and
    speech-rate (TZ §3.5.4).
    """
    ref_tokens = tokenize_words(reference_text)
    said_tokens = tokenize_words(transcript)
    ref_norm = [normalize_word(t) for t in ref_tokens]
    said_norm = [normalize_word(t) for t in said_tokens]

    # Only trust positional timings when they line up 1:1 with our tokens.
    timings = (
        spoken_timings
        if spoken_timings and len(spoken_timings) == len(said_tokens)
        else None
    )

    def _timing(j: int) -> dict | None:
        return timings[j] if timings is not None else None

    word_analyses: list[WordAnalysis] = []
    extra_words: list[str] = []

    matcher = SequenceMatcher(None, ref_norm, said_norm, autojunk=False)
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            for k in range(i2 - i1):
                idx = i1 + k
                word_analyses.append(
                    analyze_word(
                        ref_tokens[idx],
                        said_tokens[j1 + k],
                        ref_index=idx,
                        timing=_timing(j1 + k),
                    )
                )
        elif tag == "replace":
            # Pair reference/spoken words positionally; leftover refs are skips,
            # leftover spoken words are extras.
            span = min(i2 - i1, j2 - j1)
            for k in range(span):
                idx = i1 + k
                word_analyses.append(
                    analyze_word(
                        ref_tokens[idx],
                        said_tokens[j1 + k],
                        ref_index=idx,
                        timing=_timing(j1 + k),
                    )
                )
            for k in range(span, i2 - i1):
                word_analyses.append(
                    analyze_word(ref_tokens[i1 + k], None, ref_index=i1 + k)
                )
            extra_words.extend(said_tokens[j1 + span : j2])
        elif tag == "delete":
            for k in range(i2 - i1):
                word_analyses.append(
                    analyze_word(ref_tokens[i1 + k], None, ref_index=i1 + k)
                )
        elif tag == "insert":
            extra_words.extend(said_tokens[j1:j2])

    stats = build_char_stats(word_analyses)
    stats["extra_words"] = extra_words
    return word_analyses, stats

