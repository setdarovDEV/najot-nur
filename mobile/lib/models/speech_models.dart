class PronunciationReference {
  PronunciationReference({
    required this.id,
    required this.title,
    required this.text,
    required this.difficulty,
    this.referenceAudioUrl,
  });

  final String id;
  final String title;
  final String text;
  final String difficulty;
  final String? referenceAudioUrl;

  factory PronunciationReference.fromJson(Map<String, dynamic> j) =>
      PronunciationReference(
        id: j['id'] as String,
        title: j['title'] as String,
        text: j['text'] as String,
        difficulty: j['difficulty'] as String? ?? 'easy',
        referenceAudioUrl: j['reference_audio_url'] as String?,
      );
}

class WordError {
  WordError({required this.index, required this.word, required this.errorType});

  final int index;
  final String word;
  final String errorType; // mispronounced | missed

  factory WordError.fromJson(Map<String, dynamic> j) => WordError(
        index: j['index'] as int,
        word: j['word'] as String,
        errorType: j['error_type'] as String? ?? 'mispronounced',
      );
}

/// A single letter operation inside a word (TZ §3.5.4).
class CharOp {
  CharOp({
    required this.position,
    required this.expectedChar,
    required this.spokenChar,
    required this.operation,
    required this.phonemeGroup,
    required this.penalty,
    required this.tip,
  });

  final int position;
  final String? expectedChar;
  final String? spokenChar;
  final String operation; // match | substitute | delete | insert | transpose
  final String phonemeGroup; // vowel | consonant | special
  final int penalty;
  final String tip;

  bool get isError => operation != 'match';

  factory CharOp.fromJson(Map<String, dynamic> j) => CharOp(
        position: j['position'] as int? ?? 0,
        expectedChar: j['expected_char'] as String?,
        spokenChar: j['spoken_char'] as String?,
        operation: j['operation'] as String? ?? 'match',
        phonemeGroup: j['phoneme_group'] as String? ?? 'consonant',
        penalty: j['penalty'] as int? ?? 0,
        tip: j['tip'] as String? ?? '',
      );
}

/// Full character-level analysis of one reference word (TZ §3.5).
class WordAnalysis {
  WordAnalysis({
    required this.referenceWord,
    required this.spokenWord,
    required this.isCorrect,
    required this.wordScore,
    required this.levenshteinDistance,
    required this.phoneticMatch,
    required this.colorHex,
    required this.refIndex,
    required this.aiComment,
    required this.recommendation,
    required this.charOps,
  });

  final String referenceWord;
  final String? spokenWord;
  final bool isCorrect;
  final int wordScore;
  final int levenshteinDistance;
  final double phoneticMatch;
  final String colorHex; // e.g. "#FFC107"
  final int refIndex;
  final String? aiComment; // per-word explanation (TZ §3.4)
  final String? recommendation; // per-word practical tip
  final List<CharOp> charOps;

  int get errorCount => charOps.where((o) => o.isError).length;

  factory WordAnalysis.fromJson(Map<String, dynamic> j) => WordAnalysis(
        referenceWord: j['reference_word'] as String? ?? '',
        spokenWord: j['spoken_word'] as String?,
        isCorrect: j['is_correct'] as bool? ?? false,
        wordScore: j['word_score'] as int? ?? 0,
        levenshteinDistance: j['levenshtein_distance'] as int? ?? 0,
        phoneticMatch: (j['phonetic_match'] as num?)?.toDouble() ?? 0.0,
        colorHex: j['color'] as String? ?? '#4CAF50',
        refIndex: j['ref_index'] as int? ?? 0,
        aiComment: j['ai_comment'] as String?,
        recommendation: j['recommendation'] as String?,
        charOps: ((j['char_ops'] as List?) ?? [])
            .map((e) => CharOp.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class VoiceAnalysis {
  VoiceAnalysis({
    required this.id,
    required this.referenceText,
    required this.overallScore,
    required this.accuracyScore,
    required this.wordErrors,
    required this.phonemeErrors,
    required this.wordAnalysis,
    required this.charStats,
    required this.summary,
  });

  final String id;
  final String referenceText;
  final int overallScore;
  final int accuracyScore;
  final List<WordError> wordErrors;
  final List<Map<String, dynamic>> phonemeErrors;
  final List<WordAnalysis> wordAnalysis;
  final Map<String, dynamic> charStats;
  final String summary;

  Set<int> get errorIndexes => wordErrors.map((e) => e.index).toSet();

  /// Char-level analysis keyed by reference-token index, for fast UI lookup.
  Map<int, WordAnalysis> get wordAnalysisByIndex =>
      {for (final w in wordAnalysis) w.refIndex: w};

  bool get hasCharAnalysis => wordAnalysis.isNotEmpty;

  List<Map<String, dynamic>> get topProblemChars =>
      ((charStats['top_problem_chars'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  List<Map<String, dynamic>> get phonemeTips =>
      ((charStats['phoneme_tips'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  List<String> get minimalPairs => ((charStats['minimal_pairs'] as List?) ?? [])
      .map((e) => e.toString())
      .toList();

  factory VoiceAnalysis.fromJson(Map<String, dynamic> j) => VoiceAnalysis(
        id: j['id'] as String,
        referenceText: j['reference_text'] as String? ?? '',
        overallScore: j['overall_score'] as int? ?? 0,
        accuracyScore: j['accuracy_score'] as int? ?? 0,
        wordErrors: ((j['word_errors'] as List?) ?? [])
            .map((e) => WordError.fromJson(e as Map<String, dynamic>))
            .toList(),
        phonemeErrors: ((j['phoneme_errors'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        wordAnalysis: ((j['word_analysis'] as List?) ?? [])
            .map((e) => WordAnalysis.fromJson(e as Map<String, dynamic>))
            .toList(),
        charStats: Map<String, dynamic>.from((j['char_stats'] as Map?) ?? {}),
        summary: j['summary'] as String? ?? '',
      );
}

class SpeechAnalysis {
  SpeechAnalysis({
    required this.id,
    required this.overallScore,
    required this.meaningScore,
    required this.fluencyScore,
    required this.fillerWords,
    required this.infoBalance,
    required this.summary,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final int overallScore;
  final int meaningScore;
  final int fluencyScore;
  final Map<String, dynamic> fillerWords;
  final String infoBalance; // ok | too_little | too_much
  final String summary;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  List<String> get strengths =>
      ((details['strengths'] as List?) ?? []).map((e) => e.toString()).toList();
  List<String> get improvements => ((details['improvements'] as List?) ?? [])
      .map((e) => e.toString())
      .toList();

  factory SpeechAnalysis.fromJson(Map<String, dynamic> j) => SpeechAnalysis(
        id: j['id'] as String,
        overallScore: j['overall_score'] as int? ?? 0,
        meaningScore: j['meaning_score'] as int? ?? 0,
        fluencyScore: j['fluency_score'] as int? ?? 0,
        fillerWords:
            Map<String, dynamic>.from((j['filler_words'] as Map?) ?? {}),
        infoBalance: j['info_balance'] as String? ?? 'ok',
        summary: j['summary'] as String? ?? '',
        details: Map<String, dynamic>.from((j['details'] as Map?) ?? {}),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
