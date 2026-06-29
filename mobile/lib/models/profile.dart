class Certificate {
  Certificate({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.serialNumber,
    this.pdfUrl,
    this.grade,
    required this.issuedAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String serialNumber;
  final String? pdfUrl;
  final int? grade;
  final DateTime issuedAt;

  factory Certificate.fromJson(Map<String, dynamic> j) => Certificate(
        id: j['id'] as String,
        courseId: j['course_id'] as String,
        courseTitle: j['course_title'] as String,
        serialNumber: j['serial_number'] as String,
        pdfUrl: j['pdf_url'] as String?,
        grade: j['grade'] as int?,
        issuedAt: DateTime.parse(j['issued_at'] as String),
      );
}

class CertificateRequest {
  CertificateRequest({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.fullName,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String fullName;
  final String status; // pending | approved | rejected
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory CertificateRequest.fromJson(Map<String, dynamic> j) =>
      CertificateRequest(
        id: j['id'] as String,
        courseId: j['course_id'] as String,
        courseTitle: j['course_title'] as String,
        fullName: j['full_name'] as String,
        status: j['status'] as String,
        rejectionReason: j['rejection_reason'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        reviewedAt: j['reviewed_at'] == null
            ? null
            : DateTime.parse(j['reviewed_at'] as String),
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    this.sentAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String audience;
  final DateTime? sentAt;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        audience: j['audience'] as String? ?? 'all',
        sentAt: j['sent_at'] == null
            ? null
            : DateTime.parse(j['sent_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// Unified item rendered in the analysis-history list.
enum HistoryKind { speech, voice, observation }

class HistoryItem {
  HistoryItem({
    required this.id,
    required this.kind,
    this.subtitle,
    this.meaningScore,
    this.fluencyScore,
    required this.score,
    required this.createdAt,
  });

  final String id;
  final HistoryKind kind;
  final String? subtitle;
  final int? meaningScore;
  final int? fluencyScore;
  final int? score;
  final DateTime createdAt;
}
