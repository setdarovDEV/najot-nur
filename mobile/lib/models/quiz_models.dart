class QuizSummary {
  QuizSummary({
    required this.id,
    required this.title,
    this.description,
    required this.difficulty,
    required this.questionCount,
    this.category,
    required this.status,
    this.coverImageUrl,
    this.videoUrl,
  });

  final String id;
  final String title;
  final String? description;
  final String difficulty;
  final int questionCount;
  final String? category;
  final String status;
  final String? coverImageUrl;
  final String? videoUrl;

  factory QuizSummary.fromJson(Map<String, dynamic> j) => QuizSummary(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        difficulty: j['difficulty'] as String? ?? 'medium',
        questionCount: j['question_count'] as int? ?? 0,
        category: j['category'] as String?,
        status: j['status'] as String? ?? 'approved',
        coverImageUrl: j['cover_image_url'] as String?,
        videoUrl: j['video_url'] as String?,
      );
}

class QuizQuestion {
  QuizQuestion({
    required this.question,
    required this.options,
    this.imageUrl,
    this.videoUrl,
  });

  final String question;
  final List<String> options;
  final String? imageUrl;
  final String? videoUrl;

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['question'] as String,
        options: (j['options'] as List).cast<String>(),
        imageUrl: j['image_url'] as String?,
        videoUrl: j['video_url'] as String?,
      );
}

class QuizDetail {
  QuizDetail({
    required this.id,
    required this.title,
    this.description,
    required this.difficulty,
    required this.questions,
    this.coverImageUrl,
    this.videoUrl,
  });

  final String id;
  final String title;
  final String? description;
  final String difficulty;
  final List<QuizQuestion> questions;
  final String? coverImageUrl;
  final String? videoUrl;

  factory QuizDetail.fromJson(Map<String, dynamic> j) => QuizDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        difficulty: j['difficulty'] as String? ?? 'medium',
        questions: (j['questions'] as List)
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        coverImageUrl: j['cover_image_url'] as String?,
        videoUrl: j['video_url'] as String?,
      );
}

class QuizAttemptResult {
  QuizAttemptResult({
    required this.id,
    required this.score,
    required this.correctCount,
    required this.totalCount,
  });

  final String id;
  final int score;
  final int correctCount;
  final int totalCount;

  factory QuizAttemptResult.fromJson(Map<String, dynamic> j) =>
      QuizAttemptResult(
        id: j['id'] as String,
        score: j['score'] as int? ?? 0,
        correctCount: j['correct_count'] as int? ?? 0,
        totalCount: j['total_count'] as int? ?? 0,
      );
}

class PracticeText {
  PracticeText({required this.text, required this.title, required this.difficulty});

  final String text;
  final String title;
  final String difficulty;

  factory PracticeText.fromJson(Map<String, dynamic> j) => PracticeText(
        text: j['text'] as String,
        title: j['title'] as String? ?? 'Mashq matni',
        difficulty: j['difficulty'] as String? ?? 'medium',
      );
}
