import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/network/api_client.dart';

/// Wires FCM into the app: initialises Firebase, requests permission, fetches
/// the device token, registers it with the backend, and shows incoming pushes
/// as local notifications when the app is in the foreground.
///
/// Safe to call on a device without Firebase configured (no google-services
/// on Android, no GoogleService-Info on iOS): every call is wrapped in a
/// try/catch and the service degrades to a no-op.
class PushService {
  PushService(this._api);

  final ApiClient _api;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// Called when an order-status push arrives (foreground or background-to-fg).
  /// The app wires this up in [_NotiqAiAppState] to invalidate Riverpod providers.
  void Function(String orderStatus, String courseId, String audiobookId)?
      onOrderStatusChanged;

  /// Called when the user taps a notification — navigate to a given route.
  void Function(String route)? onNavigate;

  static const _channelId = 'notiqai_push_high';
  static const _channelName = 'Muhim xabarlar';
  static const _channelDesc = 'Kurator va admin e\'lonlari';

  bool _initialised = false;
  String? _lastToken;

  bool get isSupported => !kIsWeb;

  /// Call once at app start. Idempotent.
  Future<void> init() async {
    if (!isSupported || _initialised) return;
    _initialised = true;
    try {
      await Firebase.initializeApp();
    } catch (e, st) {
      debugPrint('PushService: Firebase init failed ($e) — push disabled. '
          'Check google-services.json (Android) / GoogleService-Info.plist (iOS).');
      debugPrintStack(stackTrace: st);
      return;
    }
    try {
      await _initLocalChannel();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onBackgroundMessage(_onBackground);
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedFromBackground);

      // Cold-start: app was closed and user tapped the notification.
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleOrderMessage(initialMessage, navigate: true);
      }

      // Initial token + listen for rotation.
      await _refreshToken();
      messaging.onTokenRefresh.listen((t) => _register(t));
    } catch (e, st) {
      debugPrint('PushService: setup failed ($e)');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Register the current FCM token with the backend (POST /users/me/push-token).
  /// Called automatically after init and on token rotation. Safe to call
  /// multiple times — the backend upserts on the unique token.
  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) return;
    _lastToken = token;
    try {
      final platform = _detectPlatform();
      await _api.dio.post(
        '/users/me/push-token',
        data: {
          'token': token,
          'platform': platform,
        },
      );
      debugPrint('PushService: token registered (platform=$platform, '
          'token=${token.substring(0, 8)}…)');
    } catch (e) {
      debugPrint('PushService: register failed ($e)');
    }
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      // Platform.isX may throw on some targets.
    }
    return defaultTargetPlatform.name;
  }

  Future<void> _refreshToken() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      await _register(t);
    } catch (e) {
      debugPrint('PushService: getToken failed ($e). '
          'Firebase toʻgʻri sozlanganligini tekshiring.');
    }
  }

  Future<void> _initLocalChannel() async {
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(init);
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  void _onForeground(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString() ?? 'NotiqAI';
    final body = n?.body ?? message.data['body']?.toString() ?? '';
    _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['notification_id']?.toString(),
    );
    // Refresh app state so course/audiobook access reflects the new status.
    _handleOrderMessage(message, navigate: false);
  }

  void _onOpenedFromBackground(RemoteMessage message) {
    debugPrint('PushService: opened from background ${message.messageId}');
    _handleOrderMessage(message, navigate: true);
  }

  void _handleOrderMessage(RemoteMessage message, {required bool navigate}) {
    if (message.data['kind'] != 'order_status') return;
    final status = message.data['order_status']?.toString() ?? '';
    final courseId = message.data['course_id']?.toString() ?? '';
    final audiobookId = message.data['audiobook_id']?.toString() ?? '';
    onOrderStatusChanged?.call(status, courseId, audiobookId);
    if (navigate) {
      // Navigate to orders so the user sees the updated status.
      onNavigate?.call('/profile/orders');
    }
  }

  String? get lastToken => _lastToken;
}

/// Top-level (must be top-level) handler for messages received while the app
/// is terminated. Shows a silent local notification; the OS will redeliver
/// the data when the user opens the app.
@pragma('vm:entry-point')
Future<void> _onBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  final n = message.notification;
  await local.show(
    message.hashCode,
    n?.title ?? 'NotiqAI',
    n?.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'notiqai_push_high',
        'Muhim xabarlar',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}
