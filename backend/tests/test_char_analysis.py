"""Tests for the deep character-level analysis module (TZ §3.5).

These cover the worked example from the spec plus the penalty scheme, grapheme
splitting, phoneme grouping, transposition collapsing and the aggregate stats.
"""
from __future__ import annotations

from app.services.ai.char_analysis import (
    COLOR_GRAY,
    COLOR_GREEN,
    COLOR_RED,
    PENALTY_DELETE,
    PENALTY_INSERT,
    PENALTY_SUBSTITUTE,
    PENALTY_TRANSPOSE,
    analyze_text_chars,
    analyze_word,
    build_char_stats,
    normalize_word,
    phoneme_group,
    split_graphemes,
)


# ─────────────────── TZ §3.5.5 worked example ───────────────────
def test_maktab_maqtap_scores_94():
    """User said 'maqtap' instead of 'maktab' → 2 substitutions → 94/100."""
    wa = analyze_word("maktab", "maqtap")
    assert wa.word_score == 94
    assert wa.levenshtein_distance == 2
    assert not wa.is_correct

    errors = [op for op in wa.char_ops if op.operation != "match"]
    assert len(errors) == 2

    by_pos = {op.position: op for op in wa.char_ops}
    assert by_pos[2].operation == "substitute"
    assert (by_pos[2].expected_char, by_pos[2].spoken_char) == ("k", "q")
    assert by_pos[2].penalty == PENALTY_SUBSTITUTE
    assert by_pos[5].operation == "substitute"
    assert (by_pos[5].expected_char, by_pos[5].spoken_char) == ("b", "p")


def test_correct_word_is_green_and_100():
    wa = analyze_word("ona", "ona")
    assert wa.word_score == 100
    assert wa.is_correct
    assert wa.color == COLOR_GREEN
    assert all(op.operation == "match" for op in wa.char_ops)


# ─────────────────── Penalty scheme (TZ §3.5.2) ───────────────────
def test_deletion_penalty():
    # "maktab" -> "makab": the 't' (pos 3) is dropped.
    wa = analyze_word("maktab", "makab")
    dels = [op for op in wa.char_ops if op.operation == "delete"]
    assert len(dels) == 1
    assert dels[0].expected_char == "t"
    assert dels[0].penalty == PENALTY_DELETE
    assert wa.word_score == 100 - PENALTY_DELETE


def test_insertion_penalty():
    # "bola" -> "boola": an extra 'o' is inserted.
    wa = analyze_word("bola", "boola")
    ins = [op for op in wa.char_ops if op.operation == "insert"]
    assert len(ins) == 1
    assert ins[0].spoken_char == "o"
    assert ins[0].penalty == PENALTY_INSERT
    assert wa.word_score == 100 - PENALTY_INSERT


def test_transposition_collapsed():
    # "ab" -> "ba" should be one transposition, not two substitutions.
    wa = analyze_word("ab", "ba")
    ops = [op for op in wa.char_ops if op.operation != "match"]
    assert len(ops) == 1
    assert ops[0].operation == "transpose"
    assert ops[0].penalty == PENALTY_TRANSPOSE


def test_skipped_word_is_red_zero():
    wa = analyze_word("bolalar", None)
    assert wa.word_score == 0
    assert wa.color == COLOR_RED
    assert wa.spoken_word is None
    assert all(op.operation == "delete" for op in wa.char_ops)


# ─────────────────── Grapheme & phoneme handling (TZ §3.5.3) ───────────────────
def test_split_graphemes_keeps_multichar_units():
    assert split_graphemes("yo'lchi") == ["y", "o'", "l", "ch", "i"]
    assert split_graphemes("salom") == ["s", "a", "l", "o", "m"]
    # "ng" is treated as a single Uzbek phoneme (greedy). This is a deliberate
    # simplification: it applies consistently to both reference and spoken
    # words, so word alignment stays correct.
    assert split_graphemes("tong") == ["t", "o", "ng"]


def test_apostrophe_variants_normalize_equal():
    assert normalize_word("oʻzbek") == normalize_word("o'zbek")
    wa = analyze_word("oʻzbek", "o'zbek")
    assert wa.is_correct


def test_phoneme_groups():
    assert phoneme_group("a") == "vowel"
    assert phoneme_group("o'") == "vowel"
    assert phoneme_group("q") == "special"
    assert phoneme_group("sh") == "special"
    assert phoneme_group("m") == "consonant"


def test_voicing_tip_present_for_b_p():
    wa = analyze_word("maktab", "maqtap")
    bp = next(op for op in wa.char_ops if op.position == 5)
    assert "jarangli" in bp.tip and "jarangsiz" in bp.tip


# ─────────────────── Text-level orchestration + stats (TZ §3.5.7) ───────────────────
def test_analyze_text_aligns_and_flags_extras():
    word_analyses, stats = analyze_text_chars(
        "men maktabga bordim", "men maqtabga keldim bordim"
    )
    words = {wa.reference_word for wa in word_analyses}
    assert words == {"men", "maktabga", "bordim"}
    assert "keldim" in stats["extra_words"]


def test_char_stats_rollup():
    word_analyses, _ = analyze_text_chars("maktab kitob", "maqtap kitab")
    stats = build_char_stats(word_analyses)
    patterns = {p["pattern"] for p in stats["error_patterns"]}
    assert "k→q" in patterns  # from maktab→maqtap
    assert stats["total_char_errors"] >= 3
    assert "consonant" in stats["phoneme_group_accuracy"]


def test_every_word_has_a_comment():
    # "har bir so'zga izoh" — correct, errored and skipped words all get one.
    correct = analyze_word("ona", "ona")
    assert correct.ai_comment and "to'g'ri" in correct.ai_comment.lower()
    assert correct.recommendation is None

    errored = analyze_word("maktab", "maqtap")
    assert errored.ai_comment and "harf xatosi" in errored.ai_comment
    assert errored.recommendation

    skipped = analyze_word("bolalar", None)
    assert skipped.ai_comment and "aytilmadi" in skipped.ai_comment
    assert skipped.recommendation


def test_ops_summary_is_factual():
    wa = analyze_word("maktab", "maqtap")
    summary = wa.ops_summary()
    assert "k→q" in summary and "b→p" in summary


def test_extra_word_color_gray_in_word_analysis_absent():
    # Extra words are not graded; they only appear in stats. The graded words
    # keep their own colours.
    word_analyses, stats = analyze_text_chars("salom", "salom dunyo")
    assert all(wa.color != COLOR_GRAY for wa in word_analyses)
    assert "dunyo" in stats["extra_words"]
