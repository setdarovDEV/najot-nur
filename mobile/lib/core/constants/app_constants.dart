abstract class AppConstants {
  /// API base URL. Override at build time:
  ///   flutter run --dart-define=API_URL=http://192.168.1.10:8001/api/v1
  /// Android emulator reaches the host machine via 10.0.2.2.
  /// Real device: expose backend with cloudflared and use the https URL.
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.notiqlik.uz/api/v1',
  );

  /// WebSocket base URL. Derived from [apiUrl] when not overridden.
  /// Override at build time with:
  ///   flutter run --dart-define=WS_URL=ws://10.0.2.2:8001
  static const wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: '',
  );

  /// Sentinel URL passed as `return_url`/`callback` when creating an Uzum
  /// Nasiya installment contract. It never needs to actually load — the
  /// in-app WebView intercepts navigation the moment the URL starts with
  /// this prefix (see NasiyaWebViewScreen) and treats it as "OTP done".
  static const nasiyaReturnUrl = 'https://notiqlik.uz/nasiya-return';

  // SharedPreferences keys
  static const kAccessToken = 'access_token';
  static const kRefreshToken = 'refresh_token';
  static const kOnboardingSeen = 'onboarding_seen';
  static const kLanguage = 'app_language';

  // The guided self-introduction questions (Nutq tahlili).
  static const selfIntroQuestions = <String>[
    'Ismingiz nima?',
    'Qayerdansiz?',
    'Qayerda o\'qigansiz?',
    'Yutuqlaringiz qanday?',
    'Yaqinlaringiz haqida',
    'Asosiy maqsadingiz nima?',
  ];
}
