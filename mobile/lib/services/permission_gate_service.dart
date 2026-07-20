import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// The permissions the app cares about at the "have you granted this yet?"
/// level, independent of which feature (login audio capture, city
/// detection, push notifications) actually consumes them.
enum AppPermissionKind { camera, microphone, location, notification }

extension AppPermissionKindHandler on AppPermissionKind {
  Permission get _handler => switch (this) {
        AppPermissionKind.camera => Permission.camera,
        AppPermissionKind.microphone => Permission.microphone,
        AppPermissionKind.location => Permission.location,
        AppPermissionKind.notification => Permission.notification,
      };
}

/// Checks and (re)requests [AppPermissionKind]s.
///
/// Individual features (SecurityService, LocationService, PushService)
/// already request their own permission the moment they need it — but the
/// OS only shows its native dialog once. If the user denies it, later
/// `request()` calls resolve silently with no UI. [PermissionGateDialog]
/// uses this service to notice that gap on every app open and surface an
/// in-app prompt instead, so a denial isn't the end of the story.
class PermissionGateService {
  Future<Map<AppPermissionKind, PermissionStatus>> checkAll() async {
    final result = <AppPermissionKind, PermissionStatus>{};
    for (final kind in AppPermissionKind.values) {
      try {
        result[kind] = await kind._handler.status;
      } catch (e) {
        // Platform without this permission concept (e.g. desktop/web) —
        // treat as granted so it never blocks the app.
        debugPrint('PermissionGateService: status($kind) failed ($e)');
        result[kind] = PermissionStatus.granted;
      }
    }
    return result;
  }

  Future<PermissionStatus> request(AppPermissionKind kind) async {
    try {
      return await kind._handler.request();
    } catch (e) {
      debugPrint('PermissionGateService: request($kind) failed ($e)');
      return PermissionStatus.granted;
    }
  }

  Future<void> openSettings() => openAppSettings();
}

final permissionGateServiceProvider =
    Provider<PermissionGateService>((ref) => PermissionGateService());
