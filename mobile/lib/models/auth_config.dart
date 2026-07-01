/// Public auth configuration the backend exposes to the mobile client.
///
/// Mirrors `AuthConfigResponse` on the server. Only non-secret fields live
/// here — these identifiers are meant to be embedded in the public client.
class AuthConfig {
  const AuthConfig({
    this.googleClientId = '',
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) => AuthConfig(
        googleClientId: json['google_client_id'] as String? ?? '',
      );

  /// Google OAuth client id. Empty when Google login is not configured.
  final String googleClientId;

  bool get googleLoginEnabled => googleClientId.isNotEmpty;
}
