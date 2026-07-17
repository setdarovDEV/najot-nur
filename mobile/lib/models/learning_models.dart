class Lesson {
  Lesson({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    this.videoUrl,
    required this.durationSec,
    required this.isVoiceExercise,
    this.voiceExercisePrompt,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String? description;
  final int orderIndex;
  final String? videoUrl;
  final int durationSec;
  final bool isVoiceExercise;
  final String? voiceExercisePrompt;
  final bool isDemo;

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        orderIndex: j['order_index'] as int? ?? 0,
        videoUrl: j['video_url'] as String?,
        durationSec: j['duration_sec'] as int? ?? 0,
        isVoiceExercise: j['is_voice_exercise'] as bool? ?? false,
        voiceExercisePrompt: j['voice_exercise_prompt'] as String?,
        isDemo: j['is_demo'] as bool? ?? false,
      );
}

class Course {
  Course({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    required this.price,
    required this.level,
    this.lessons = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final num price;
  final String level;
  final List<Lesson> lessons;

  bool get isFree => price == 0;

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        coverUrl: j['cover_url'] as String?,
        price: _parsePrice(j['price']),
        level: j['level'] as String? ?? 'beginner',
        lessons: ((j['lessons'] as List?) ?? [])
            .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static num _parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }
}

class LessonQuizQuestion {
  LessonQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.orderIndex,
  });
  final String id;
  final String question;
  final List<String> options;
  final int orderIndex;

  factory LessonQuizQuestion.fromJson(Map<String, dynamic> j) =>
      LessonQuizQuestion(
        id: j['id'] as String,
        question: j['question'] as String,
        options: (j['options'] as List).cast<String>(),
        orderIndex: j['order_index'] as int? ?? 0,
      );
}

class LessonDetail {
  LessonDetail({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    required this.durationSec,
    required this.isVoiceExercise,
    this.voiceExercisePrompt,
    this.isDemo = false,
    required this.isCompleted,
    this.autoScore,
    this.questions = const [],
  });
  final String id;
  final String title;
  final String? description;
  final String? videoUrl;
  final int durationSec;
  final bool isVoiceExercise;
  final String? voiceExercisePrompt;
  final bool isDemo;
  final bool isCompleted;
  final int? autoScore;
  final List<LessonQuizQuestion> questions;

  bool get hasQuiz => questions.isNotEmpty;

  factory LessonDetail.fromJson(Map<String, dynamic> j) => LessonDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        videoUrl: j['video_url'] as String?,
        durationSec: j['duration_sec'] as int? ?? 0,
        isVoiceExercise: j['is_voice_exercise'] as bool? ?? false,
        voiceExercisePrompt: j['voice_exercise_prompt'] as String?,
        isDemo: j['is_demo'] as bool? ?? false,
        isCompleted: j['is_completed'] as bool? ?? false,
        autoScore: j['auto_score'] as int?,
        questions: ((j['questions'] as List?) ?? [])
            .map((e) => LessonQuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class EnrolledLesson {
  EnrolledLesson({
    required this.lessonId,
    required this.title,
    required this.orderIndex,
    required this.durationSec,
    required this.isVoiceExercise,
    required this.isCompleted,
    this.autoScore,
  });
  final String lessonId;
  final String title;
  final int orderIndex;
  final int durationSec;
  final bool isVoiceExercise;
  final bool isCompleted;
  final int? autoScore;

  factory EnrolledLesson.fromJson(Map<String, dynamic> j) => EnrolledLesson(
        lessonId: j['lesson_id'] as String,
        title: j['title'] as String,
        orderIndex: j['order_index'] as int? ?? 0,
        durationSec: j['duration_sec'] as int? ?? 0,
        isVoiceExercise: j['is_voice_exercise'] as bool? ?? false,
        isCompleted: j['is_completed'] as bool? ?? false,
        autoScore: j['auto_score'] as int?,
      );
}

class CourseProgress {
  CourseProgress({
    required this.enrolled,
    this.enrollmentId,
    this.status,
    this.progressPct,
    this.lessons = const [],
    this.hasPendingOrder = false,
  });
  final bool enrolled;
  final String? enrollmentId;
  final String? status;
  final int? progressPct;
  final List<EnrolledLesson> lessons;
  final bool hasPendingOrder;

  bool get isCompleted => status == 'completed';

  factory CourseProgress.fromJson(Map<String, dynamic> j) => CourseProgress(
        enrolled: j['enrolled'] as bool? ?? false,
        enrollmentId: j['enrollment_id'] as String?,
        status: j['status'] as String?,
        progressPct: j['progress_pct'] as int?,
        hasPendingOrder: j['has_pending_order'] as bool? ?? false,
        lessons: ((j['lessons'] as List?) ?? [])
            .map((e) => EnrolledLesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class HomeworkSubmission {
  HomeworkSubmission({
    required this.id,
    required this.status,
    this.submissionText,
    this.submissionUrl,
    this.curatorScore,
    this.curatorFeedback,
    this.reviewedAt,
    required this.createdAt,
  });
  final String id;
  final String status; // submitted | reviewed | returned
  final String? submissionText;
  final String? submissionUrl;
  final int? curatorScore;
  final String? curatorFeedback;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  bool get isReviewed => status == 'reviewed';

  factory HomeworkSubmission.fromJson(Map<String, dynamic> j) =>
      HomeworkSubmission(
        id: j['id'] as String,
        status: j['status'] as String,
        submissionText: j['submission_text'] as String?,
        submissionUrl: j['submission_url'] as String?,
        curatorScore: j['curator_score'] as int?,
        curatorFeedback: j['curator_feedback'] as String?,
        reviewedAt: j['reviewed_at'] == null
            ? null
            : DateTime.parse(j['reviewed_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AudiobookPage {
  AudiobookPage({required this.pageNumber, this.content, this.audioUrl});

  final int pageNumber;
  final String? content;
  final String? audioUrl;

  factory AudiobookPage.fromJson(Map<String, dynamic> j) => AudiobookPage(
        pageNumber: j['page_number'] as int,
        content: j['content'] as String?,
        audioUrl: j['audio_url'] as String?,
      );
}

class Audiobook {
  Audiobook({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.description,
    this.category,
    this.audioUrl,
    required this.isFree,
    required this.price,
    required this.totalPages,
    this.pages = const [],
  });

  final String id;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? description;
  final String? category;
  final String? audioUrl;
  final bool isFree;
  final num price;
  final int totalPages;
  final List<AudiobookPage> pages;

  factory Audiobook.fromJson(Map<String, dynamic> j) => Audiobook(
        id: j['id'] as String,
        title: j['title'] as String,
        author: j['author'] as String?,
        coverUrl: j['cover_url'] as String?,
        description: j['description'] as String?,
        category: j['category'] as String?,
        audioUrl: j['audio_url'] as String?,
        isFree: j['is_free'] as bool? ?? true,
        price: num.tryParse(j['price']?.toString() ?? '') ?? 0,
        totalPages: j['total_pages'] as int? ?? 0,
        pages: ((j['pages'] as List?) ?? [])
            .map((e) => AudiobookPage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum OrderPurpose { course, audiobook }

enum OrderPaymentMethod { uzum, uzumNasiya, cash }

enum OrderStatus { pending, approved, rejected }

extension OrderPurposeX on OrderPurpose {
  String get apiValue => name;
  static OrderPurpose fromApi(String? s) =>
      s == 'audiobook' ? OrderPurpose.audiobook : OrderPurpose.course;
}

extension OrderPaymentMethodX on OrderPaymentMethod {
  String get apiValue {
    switch (this) {
      case OrderPaymentMethod.uzum:
        return 'uzum';
      case OrderPaymentMethod.uzumNasiya:
        return 'uzum_nasiya';
      case OrderPaymentMethod.cash:
        return 'cash';
    }
  }

  static OrderPaymentMethod fromApi(String? s) {
    switch (s) {
      case 'uzum':
        return OrderPaymentMethod.uzum;
      case 'uzum_nasiya':
        return OrderPaymentMethod.uzumNasiya;
      case 'cash':
        return OrderPaymentMethod.cash;
      default:
        return OrderPaymentMethod.cash;
    }
  }
}

extension OrderStatusX on OrderStatus {
  String get apiValue => name;
  static OrderStatus fromApi(String? s) {
    switch (s) {
      case 'approved':
        return OrderStatus.approved;
      case 'rejected':
        return OrderStatus.rejected;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderRequest {
  OrderRequest({
    required this.id,
    required this.purpose,
    this.courseId,
    this.audiobookId,
    this.targetTitle,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.paymentProofUrl,
    this.adminNote,
    required this.createdAt,
  });

  final String id;
  final OrderPurpose purpose;
  final String? courseId;
  final String? audiobookId;
  final String? targetTitle;
  final num amount;
  final String currency;
  final OrderPaymentMethod paymentMethod;
  final OrderStatus status;
  final String? paymentProofUrl;
  final String? adminNote;
  final DateTime createdAt;

  factory OrderRequest.fromJson(Map<String, dynamic> j) => OrderRequest(
        id: j['id'] as String,
        purpose: OrderPurposeX.fromApi(j['purpose'] as String?),
        courseId: j['course_id'] as String?,
        audiobookId: j['audiobook_id'] as String?,
        targetTitle: j['target_title'] as String?,
        amount: num.tryParse(j['amount'].toString()) ?? 0,
        currency: (j['currency'] as String?) ?? 'UZS',
        paymentMethod:
            OrderPaymentMethodX.fromApi(j['payment_method'] as String?),
        status: OrderStatusX.fromApi(j['status'] as String?),
        paymentProofUrl: j['payment_proof_url'] as String?,
        adminNote: j['admin_note'] as String?,
        createdAt:
            DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class PaymentRedirect {
  PaymentRedirect({
    required this.paymentId,
    required this.redirectUrl,
    required this.status,
    this.requiresRegistration = false,
  });

  final String paymentId;
  final String redirectUrl;
  final String status;

  /// Uzum Nasiya only: [redirectUrl] is Uzum's registration webview, not an
  /// OTP page — no contract exists yet, so don't call confirm afterwards.
  final bool requiresRegistration;

  factory PaymentRedirect.fromJson(Map<String, dynamic> j) => PaymentRedirect(
        paymentId: (j['payment_id'] ?? '').toString(),
        redirectUrl: (j['redirect_url'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        requiresRegistration: (j['requires_registration'] ?? false) as bool,
      );
}

/// One installment tariff the buyer can pick (from /uzum-nasiya/check-status
/// or /uzum-nasiya/calculate).
class NasiyaTariff {
  NasiyaTariff({
    required this.period,
    required this.titleUz,
    required this.titleRu,
    this.monthlyPayment,
    this.total,
  });

  /// Tariff id to send back as `period` when creating the order.
  final String period;
  final String titleUz;
  final String titleRu;
  /// Present only when returned from /calculate (exact sums for this price).
  final num? monthlyPayment;
  final num? total;

  factory NasiyaTariff.fromCheckStatus(Map<String, dynamic> j) => NasiyaTariff(
        period: (j['period'] ?? '').toString(),
        titleUz: (j['title_uz'] ?? '') as String,
        titleRu: (j['title_ru'] ?? '') as String,
      );

  factory NasiyaTariff.fromCalculate(Map<String, dynamic> j) => NasiyaTariff(
        period: (j['tariff'] ?? '').toString(),
        titleUz: (j['title_uz'] ?? j['tariff_name'] ?? j['tariff'] ?? '').toString(),
        titleRu: (j['title_ru'] ?? j['tariff_name'] ?? j['tariff'] ?? '').toString(),
        monthlyPayment: num.tryParse(j['month']?.toString() ?? ''),
        total: num.tryParse(j['total']?.toString() ?? ''),
      );
}

/// Uzum Nasiya buyer registration status (POST /payments/uzum-nasiya/check-status).
class NasiyaAvailability {
  NasiyaAvailability({required this.available, required this.message});

  /// False while the backend's circuit breaker is open (Uzum Nasiya having
  /// technical issues) — the mobile app should disable the payment option.
  final bool available;
  final String message;

  factory NasiyaAvailability.fromJson(Map<String, dynamic> j) =>
      NasiyaAvailability(
        available: (j['available'] ?? true) as bool,
        message: (j['message'] ?? '') as String,
      );
}

class NasiyaStatus {
  NasiyaStatus({
    required this.status,
    required this.isVerified,
    required this.hasLimit,
    required this.webview,
    required this.availablePeriods,
  });

  final int status;
  /// status == 4 means the buyer can take a contract right away.
  final bool isVerified;
  /// Whether Uzum has granted the buyer a credit limit. A status-4 buyer
  /// without a limit cannot create a contract (Uzum's order API even 500s
  /// for such buyers), so treat them as still needing registration.
  final bool hasLimit;
  /// Open in a WebView when [isVerified] is false so the buyer can finish
  /// Uzum's own registration.
  final String webview;
  final List<NasiyaTariff> availablePeriods;

  factory NasiyaStatus.fromJson(Map<String, dynamic> j) {
    final status = j['status'] as int? ?? 0;
    return NasiyaStatus(
      status: status,
      isVerified: status == 4,
      hasLimit: (j['has_limit'] ?? false) as bool,
      webview: (j['webview'] ?? '') as String,
      availablePeriods: ((j['available_periods'] as List?) ?? [])
          .map((e) => NasiyaTariff.fromCheckStatus(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AudiobookAccessStatus {
  AudiobookAccessStatus({
    required this.state,
    required this.reason,
    required this.hasPendingOrder,
  });

  /// 'granted' = user can read; 'locked' = paid gate shown.
  final String state;
  /// 'free' | 'purchased' | 'pending' | 'none'
  final String reason;
  final bool hasPendingOrder;

  bool get canRead => state == 'granted';

  factory AudiobookAccessStatus.fromJson(Map<String, dynamic> j) =>
      AudiobookAccessStatus(
        state: (j['state'] as String?) ?? 'locked',
        reason: (j['reason'] as String?) ?? 'none',
        hasPendingOrder: (j['has_pending_order'] as bool?) ?? false,
      );
}
