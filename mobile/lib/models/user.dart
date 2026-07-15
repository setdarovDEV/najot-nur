class AppUser {
  AppUser({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    required this.role,
    this.avatarUrl,
    this.pinfl,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String role;
  final String? avatarUrl;
  final String? pinfl;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        fullName: j['full_name'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        role: j['role'] as String? ?? 'user',
        avatarUrl: j['avatar_url'] as String?,
        pinfl: j['pinfl'] as String?,
      );

  String get displayName =>
      fullName?.trim().isNotEmpty == true ? fullName! : (phone ?? 'Foydalanuvchi');
}
