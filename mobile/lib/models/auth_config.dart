/// Public auth configuration the backend exposes to the mobile client.
///
/// Mirrors `AuthConfigResponse` on the server. Only non-secret fields live
/// here — these identifiers are meant to be embedded in the public client.
class AuthConfig {
  const AuthConfig({
    this.telegramBotUsername = '',
    this.googleClientId = '',
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) => AuthConfig(
        telegramBotUsername: json['telegram_bot_username'] as String? ?? '',
        googleClientId: json['google_client_id'] as String? ?? '',
      );

  /// Telegram bot username (without `@`). Empty when the server hasn't
  /// configured a Telegram login bot.
  final String telegramBotUsername;

  /// Google OAuth client id. Empty when Google login is not configured.
  final String googleClientId;

  bool get telegramLoginEnabled => telegramBotUsername.isNotEmpty;
  bool get googleLoginEnabled => googleClientId.isNotEmpty;
}
