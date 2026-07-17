import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/network/api_client.dart';
import '../core/network/token_store.dart';
import '../data/repositories.dart';
import '../models/user.dart';
import '../providers/providers.dart';
import '../shared/widgets/secure_screen.dart';
import 'security_channel.dart';

/// State broadcast for the rest of the UI.
@immutable
class SecurityStatus {
  const SecurityStatus({
    this.sessionId,
    this.watermarkText = '',
    this.isCaptured = false,
    this.isRooted = false,
    this.recording = false,
    this.lastError,
  });

  final String? sessionId;
  final String watermarkText;
  final bool isCaptured;
  final bool isRooted;
  final bool recording;
  final String? lastError;

  SecurityStatus copyWith({
    String? sessionId,
    String? watermarkText,
    bool? isCaptured,
    bool? isRooted,
    bool? recording,
    String? lastError,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return SecurityStatus(
      sessionId: clearSession ? null : (sessionId ?? this.sessionId),
      watermarkText: watermarkText ?? this.watermarkText,
      isCaptured: isCaptured ?? this.isCaptured,
      isRooted: isRooted ?? this.isRooted,
      recording: recording ?? this.recording,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class SecurityService {
  SecurityService({
    required this.api,
    required this.tokens,
    required this.prefs,
  });

  final ApiClient api;
  final TokenStore tokens;
  final SharedPreferences prefs;

  final ValueNotifier<SecurityStatus> status =
      ValueNotifier(const SecurityStatus());

  Timer? _heartbeatTimer;
  StreamSubscription<bool>? _captureSub;
  final AudioRecorder _recorder = AudioRecorder();
  String? _localRecordingPath;
  DateTime? _recordingStartedAt;

  // ────────── public API ──────────

  /// Called by [AuthController.onAuthenticated]. The flow is:
  /// 1) make sure FLAG_SECURE is on (Android) / capture observer is live (iOS);
  /// 2) ask for camera + microphone permissions (auto recording only happens
  ///    if the user grants them);
  /// 3) open a server-side session;
  /// 4) start the heartbeat timer;
  /// 5) record a 5-second audio clip and upload it as identity proof.
  Future<void> onLogin(AppUser user) async {
    try {
      // FLAG_SECURE is no longer applied app-wide — screenshots/recording are
      // allowed everywhere except the paid video-lesson screens, which toggle
      // it themselves via SecureScreen (shared/widgets/secure_screen.dart).
      // Don't clear the flag if a secure screen happens to be on stack.
      if (!SecureScreen.protectionActive.value) {
        await SecurityChannel.instance.setSecure(enabled: false);
      }

      // Subscribe to native capture / mirror events.
      _captureSub ??= SecurityChannel.instance.onCaptureChanged.listen((cap) {
        status.value = status.value.copyWith(isCaptured: cap);
        _reportEventIfActive(
          type: cap
              ? 'screen_capture_attempt'
              : 'session_heartbeat',
          payload: {'captured': cap},
        );
      });

      // Read device + app metadata to send to the server.
      final deviceInfo = await _readDeviceInfo();
      final appInfo = await _readAppInfo();
      final deviceId = await _deviceId();

      // Open the server-side session.
      final repo = SecurityRepository(api);
      final start = await repo.startSession(
        platform: _platformName(),
        osVersion: deviceInfo['os_version'] as String?,
        appVersion: appInfo.version,
        deviceModel: deviceInfo['device_model'] as String?,
        deviceId: deviceId,
        locale: deviceInfo['locale'] as String?,
      );
      status.value = status.value.copyWith(
        sessionId: start.sessionId,
        watermarkText: start.watermarkText,
      );

      // Schedule heartbeat (every 60s).
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => _heartbeat(repo, start.sessionId),
      );

      // Best-effort 5-second audio capture for identity binding. We don't
      // block the login flow on this — if the user denied the mic, we
      // record a permission_denied_microphone event and move on.
      unawaited(_captureLoginAudio(user, start.sessionId));
    } catch (e) {
      status.value = status.value.copyWith(lastError: e.toString());
      debugPrint('SecurityService.onLogin failed: $e');
    }
  }

  /// Called by [AuthController.logout].
  Future<void> onLogout() async {
    final sessionId = status.value.sessionId;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _stopRecording();
    if (sessionId != null) {
      try {
        await SecurityRepository(api).endSession(sessionId, reason: 'logout');
      } catch (e) {
        debugPrint('endSession failed: $e');
      }
    }
    status.value = const SecurityStatus();
  }

  /// Toggle FLAG_SECURE at runtime (e.g. disable during onboarding to allow
  /// users to take a profile photo).
  Future<void> setSecure(bool enabled) async {
    await SecurityChannel.instance.setSecure(enabled: enabled);
  }

  /// Refresh the watermark text shown across the UI. The server may rotate
  /// the text on heartbeat — the next render picks it up automatically.
  void updateWatermark(String text) {
    if (text.isEmpty) return;
    status.value = status.value.copyWith(watermarkText: text);
  }

  /// Snapshot for read-only widgets.
  SecurityStatus get currentStatus => status.value;

  void dispose() {
    _heartbeatTimer?.cancel();
    _captureSub?.cancel();
    _recorder.dispose();
    status.dispose();
  }

  // ────────── internals ──────────

  Future<void> _heartbeat(SecurityRepository repo, String sessionId) async {
    try {
      final wm = await repo.heartbeat(sessionId: sessionId);
      if (wm.isNotEmpty) updateWatermark(wm);
    } catch (e) {
      debugPrint('heartbeat failed: $e');
    }
  }

  Future<void> _captureLoginAudio(AppUser user, String sessionId) async {
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        await SecurityRepository(api).reportEvent(
          sessionId: sessionId,
          type: 'permission_denied_microphone',
          note: 'mic=${mic.name}',
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/login_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _localRecordingPath = path;
      final hasRecorder = await _recorder.hasPermission();
      if (!hasRecorder) {
        await SecurityRepository(api).reportEvent(
          sessionId: sessionId,
          type: 'permission_denied_microphone',
          note: 'no recorder permission',
        );
        return;
      }
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path,
      );
      _recordingStartedAt = DateTime.now();
      status.value = status.value.copyWith(recording: true);

      // Capture for 5 seconds.
      await Future.delayed(const Duration(seconds: 5));
      await _stopRecording();

      final duration = _recordingStartedAt != null
          ? DateTime.now().difference(_recordingStartedAt!).inSeconds
          : 0;
      await SecurityRepository(api).uploadRecording(
        sessionId: sessionId,
        filePath: path,
        kind: 'audio',
        durationSec: duration,
        note: 'auto login capture for user ${user.id}',
      );
    } catch (e) {
      debugPrint('auto audio capture failed: $e');
    } finally {
      await _stopRecording();
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    if (_localRecordingPath != null) {
      try {
        final file = File(_localRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _localRecordingPath = null;
    }
    _recordingStartedAt = null;
    if (status.value.recording) {
      status.value = status.value.copyWith(recording: false);
    }
  }

  Future<void> _reportEventIfActive({
    required String type,
    Map<String, dynamic>? payload,
    String? note,
  }) async {
    final sessionId = status.value.sessionId;
    if (sessionId == null) return;
    try {
      await SecurityRepository(api).reportEvent(
        sessionId: sessionId,
        type: type,
        payload: payload,
        note: note,
      );
    } catch (e) {
      debugPrint('reportEvent failed: $e');
    }
  }

  Future<Map<String, dynamic>> _readDeviceInfo() async {
    final device = SecurityChannel.instance.getDeviceInfo();
    final fromNative = await device;
    if (fromNative.isNotEmpty) {
      // The native side never knows the system locale; enrich it with
      // Platform.localeName (always available on mobile).
      fromNative['locale'] = Platform.localeName;
      return fromNative;
    }
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        return {
          'platform': 'android',
          'os_version': a.version.release,
          'sdk_int': a.version.sdkInt,
          'device_model': a.model,
          'locale': Platform.localeName,
        };
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        return {
          'platform': 'ios',
          'os_version': i.systemVersion,
          'device_model': i.utsname.machine,
          'locale': Platform.localeName,
        };
      }
    } catch (_) {}
    return {'locale': Platform.localeName};
  }

  Future<PackageInfo> _readAppInfo() async {
    return await PackageInfo.fromPlatform();
  }

  Future<String> _deviceId() async {
    var id = prefs.getString('security_device_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('security_device_id', id);
    }
    return id;
  }

  String _platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}

// ────────── Riverpod plumbing ──────────
final securityServiceProvider = Provider<SecurityService>((ref) {
  final svc = SecurityService(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStoreProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});

/// Broadcast provider so widgets can listen with [ValueListenableBuilder].
final securityStatusProvider = StreamProvider<SecurityStatus>((ref) async* {
  final svc = ref.watch(securityServiceProvider);
  yield svc.currentStatus;
  await for (final s in Stream<SecurityStatus>.multi((controller) {
    void listener() => controller.add(svc.status.value);
    listener();
    svc.status.addListener(listener);
    controller.onCancel = () => svc.status.removeListener(listener);
  })) {
    yield s;
  }
});
