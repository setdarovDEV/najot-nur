import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Thin wrapper over the native `notiqai/security` [MethodChannel].
///
/// Both Android (`MainActivity.kt`) and iOS (`AppDelegate.swift`) install a
/// handler with the same method names. Android additionally listens for
/// `FLAG_SECURE` bypasses; iOS listens for
/// `UIScreen.capturedDidChangeNotification`. The Dart side does not care
/// which platform is responding — it just gets stream events.
class SecurityChannel {
  SecurityChannel._();
  static final SecurityChannel instance = SecurityChannel._();

  static const MethodChannel _channel = MethodChannel('notiqai/security');

  final StreamController<bool> _captureController =
      StreamController<bool>.broadcast();

  /// Fires whenever the host OS reports a screen-capture / mirroring state
  /// change. True == a screen recorder, AirPlay mirroring, or external
  /// display is active.
  Stream<bool> get onCaptureChanged => _captureController.stream;

  bool _initialized = false;
  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenCapturedChanged') {
        final captured =
            (call.arguments as Map?)?['captured'] as bool? ?? false;
        _captureController.add(captured);
      }
    });
  }

  Future<bool> setSecure({required bool enabled}) async {
    _ensureInit();
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final res = await _channel.invokeMethod<bool>(
        'setSecure',
        {'enabled': enabled},
      );
      return res ?? enabled;
    } on PlatformException {
      return enabled;
    } on MissingPluginException {
      return enabled;
    }
  }

  Future<bool> isCaptured() async {
    _ensureInit();
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isCaptured');
      return res ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isRooted() async {
    _ensureInit();
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isRooted');
      return res ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    _ensureInit();
    if (!Platform.isAndroid && !Platform.isIOS) return {};
    try {
      final res = await _channel.invokeMethod<Map>('getDeviceInfo');
      return (res ?? const <String, dynamic>{}).cast<String, dynamic>();
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  Future<bool> isSecure() async {
    _ensureInit();
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      final res = await _channel.invokeMethod<bool>('isSecure');
      return res ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }
}
