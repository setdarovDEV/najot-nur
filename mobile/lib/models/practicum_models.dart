class PracticumSubmission {
  PracticumSubmission({
    required this.id,
    required this.practicumId,
    required this.status,
    required this.createdAt,
    this.audioUrl,
    this.transcript,
    this.overallScore,
    this.accuracyScore,
    this.wordErrors,
    this.wordAnalysis,
    this.charStats,
    this.phonemeErrors,
    this.summary,
  });

  final String id;
  final String practicumId;
  final String status;
  final DateTime createdAt;
  final String? audioUrl;
  final String? transcript;
  final int? overallScore;
  final int? accuracyScore;
  final List<dynamic>? wordErrors;
  final List<dynamic>? wordAnalysis;
  final Map<String, dynamic>? charStats;
  final List<dynamic>? phonemeErrors;
  final String? summary;

  bool get isDone => status == 'done';
  bool get isPending => status == 'pending';

  factory PracticumSubmission.fromJson(Map<String, dynamic> j) =>
      PracticumSubmission(
        id: j['id'] as String,
        practicumId: j['practicum_id'] as String,
        status: j['status'] as String? ?? 'pending',
        createdAt:
            DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        audioUrl: j['audio_url'] as String?,
        transcript: j['transcript'] as String?,
        overallScore: j['overall_score'] as int?,
        accuracyScore: j['accuracy_score'] as int?,
        wordErrors: j['word_errors'] as List?,
        wordAnalysis: j['word_analysis'] as List?,
        charStats: j['char_stats'] != null
            ? Map<String, dynamic>.from(j['char_stats'] as Map)
            : null,
        phonemeErrors: j['phoneme_errors'] as List?,
        summary: j['summary'] as String?,
      );
}

class Practicum {
  const Practicum({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.expertText,
    this.expertAudioUrl,
    required this.isFree,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? expertText;
  final String? expertAudioUrl;
  final bool isFree;
  final double price;
  final String status;
  final DateTime createdAt;

  factory Practicum.fromJson(Map<String, dynamic> json) => Practicum(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        expertText: json['expert_text'] as String?,
        expertAudioUrl: json['expert_audio_url'] as String?,
        isFree: json['is_free'] as bool? ?? true,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'draft',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
