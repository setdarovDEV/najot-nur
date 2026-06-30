class PsychologyTest {
  PsychologyTest({
    required this.id,
    required this.orderIndex,
    required this.title,
    required this.prompt,
    required this.mediaType,
    this.mediaUrl,
    required this.options,
    required this.category,
  });

  final String id;
  final int orderIndex;
  final String title;
  final String prompt;
  final String mediaType; // image | video
  final String? mediaUrl;
  final List<String> options;
  final String category;

  factory PsychologyTest.fromJson(Map<String, dynamic> j) => PsychologyTest(
        id: j['id'] as String,
        orderIndex: j['order_index'] as int? ?? 0,
        title: j['title'] as String,
        prompt: j['prompt'] as String,
        mediaType: j['media_type'] as String? ?? 'image',
        mediaUrl: j['media_url'] as String?,
        options:
            ((j['options'] as List?) ?? []).map((e) => e.toString()).toList(),
        category: j['category'] as String? ?? 'general',
      );
}

class PsychologyAnswer {
  PsychologyAnswer({required this.testId, required this.optionIndex});

  final String testId;
  final int optionIndex;

  Map<String, dynamic> toJson() =>
      {'test_id': testId, 'selected_option': optionIndex};
}

class PsychologyAttempt {
  PsychologyAttempt({
    required this.id,
    required this.score,
    required this.summary,
    required this.analysis,
    required this.answers,
    required this.createdAt,
  });

  final String id;
  final int? score;
  final String? summary;
  final Map<String, dynamic> analysis;
  final List<PsychologyAnswer> answers;
  final DateTime createdAt;

  List<String> get strengths => ((analysis['strengths'] as List?) ?? [])
      .map((e) => e.toString())
      .toList();
  List<String> get improvements => ((analysis['improvements'] as List?) ?? [])
      .map((e) => e.toString())
      .toList();
  String? get aiAnalysis => analysis['ai_analysis'] as String?;

  factory PsychologyAttempt.fromJson(Map<String, dynamic> j) =>
      PsychologyAttempt(
        id: j['id'] as String,
        score: j['score'] as int?,
        summary: j['summary'] as String?,
        analysis: Map<String, dynamic>.from((j['analysis'] as Map?) ?? {}),
        answers: ((j['answers'] as List?) ?? [])
            .map((e) => PsychologyAnswer(
                  testId: (e as Map<String, dynamic>)['test_id'] as String,
                  optionIndex:
                      (e['selected_option'] as int?) ?? 0,
                ))
            .toList(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
