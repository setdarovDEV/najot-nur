class ObservationTest {
  ObservationTest({
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

  factory ObservationTest.fromJson(Map<String, dynamic> j) => ObservationTest(
        id: j['id'] as String,
        orderIndex: j['order_index'] as int? ?? 0,
        title: j['title'] as String,
        prompt: j['prompt'] as String,
        mediaType: j['media_type'] as String? ?? 'image',
        mediaUrl: j['media_url'] as String?,
        options:
            ((j['options'] as List?) ?? []).map((e) => e.toString()).toList(),
        category: j['category'] as String? ?? 'observation',
      );
}

class ObservationAttempt {
  ObservationAttempt({
    required this.id,
    required this.score,
    required this.summary,
    required this.analysis,
    required this.createdAt,
  });

  final String id;
  final int? score;
  final String? summary;
  final Map<String, dynamic> analysis;
  final DateTime createdAt;

  List<String> get strengths => ((analysis['strengths'] as List?) ?? [])
      .map((e) => e.toString())
      .toList();
  List<String> get improvements => ((analysis['improvements'] as List?) ?? [])
      .map((e) => e.toString())
      .toList();

  factory ObservationAttempt.fromJson(Map<String, dynamic> j) =>
      ObservationAttempt(
        id: j['id'] as String,
        score: j['score'] as int?,
        summary: j['summary'] as String?,
        analysis: Map<String, dynamic>.from((j['analysis'] as Map?) ?? {}),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
