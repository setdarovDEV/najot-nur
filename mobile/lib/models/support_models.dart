class SupportMessage {
  SupportMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.isFromUser,
    required this.createdAt,
    this.sentBy,
  });

  final String id;
  final String userId;
  final String text;
  final bool isFromUser;
  final DateTime createdAt;
  final String? sentBy;

  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        text: j['text'] as String,
        isFromUser: j['is_from_user'] as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
        sentBy: j['sent_by'] as String?,
      );
}
