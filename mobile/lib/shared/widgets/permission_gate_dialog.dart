import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../services/permission_gate_service.dart';

/// Full-screen prompt shown on top of the app whenever one or more of
/// [AppPermissionKind] hasn't been granted yet.
///
/// The OS permission dialog only ever shows once — after that, denials are
/// silent. This widget re-checks every permission each time the app is
/// opened (and each time it resumes from the background) and, if anything
/// is still missing, asks again: a normal re-request if the OS will still
/// show its dialog, or a "go to Settings" prompt once the user has
/// permanently denied it. The user can dismiss it for the current session
/// with "Keyinroq" — it reappears the next time the app is opened as long
/// as the permission is still missing.
class PermissionGateDialog extends ConsumerStatefulWidget {
  const PermissionGateDialog({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PermissionGateDialog> createState() =>
      _PermissionGateDialogState();
}

class _PermissionGateDialogState extends ConsumerState<PermissionGateDialog>
    with WidgetsBindingObserver {
  Map<AppPermissionKind, PermissionStatus>? _statuses;
  bool _dismissedThisSession = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user may have just come back from the system Settings screen
      // after granting a permission there — re-check instead of waiting
      // for the next cold start.
      _dismissedThisSession = false;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final statuses =
        await ref.read(permissionGateServiceProvider).checkAll();
    if (mounted) setState(() => _statuses = statuses);
  }

  List<AppPermissionKind> get _missing => (_statuses ?? const {})
      .entries
      .where((e) => !e.value.isGranted && !e.value.isLimited)
      .map((e) => e.key)
      .toList();

  Future<void> _grantAll() async {
    setState(() => _requesting = true);
    final service = ref.read(permissionGateServiceProvider);
    for (final kind in _missing) {
      final status = _statuses![kind]!;
      if (status.isPermanentlyDenied) {
        await service.openSettings();
        break;
      }
      final result = await service.request(kind);
      _statuses = {..._statuses!, kind: result};
    }
    if (mounted) setState(() => _requesting = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(
        authControllerProvider.select((s) => s.isLoggedIn));

    // Permissions only matter once the user is signed in (that's when
    // SecurityService/LocationService/PushService actually use them), and
    // we re-check fresh every time login state flips true.
    if (!isLoggedIn) {
      return widget.child;
    }
    if (_statuses == null) {
      // Fire the first check; render the app unblocked in the meantime.
      Future.microtask(_refresh);
      return widget.child;
    }

    final missing = _missing;
    if (missing.isEmpty || _dismissedThisSession) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _PermissionCard(
                      missing: missing,
                      statuses: _statuses!,
                      requesting: _requesting,
                      onGrant: _grantAll,
                      onLater: () =>
                          setState(() => _dismissedThisSession = true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.missing,
    required this.statuses,
    required this.requesting,
    required this.onGrant,
    required this.onLater,
  });

  final List<AppPermissionKind> missing;
  final Map<AppPermissionKind, PermissionStatus> statuses;
  final bool requesting;
  final VoidCallback onGrant;
  final VoidCallback onLater;

  bool get _anyPermanentlyDenied =>
      missing.any((k) => statuses[k]!.isPermanentlyDenied);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.wine100,
                child: Icon(
                  Icons.privacy_tip_rounded,
                  size: 32,
                  color: AppColors.wine,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.permissionGateTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.permissionGateMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...missing.map((kind) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(_iconFor(kind), size: 18, color: AppColors.wine),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _labelFor(l, kind),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: requesting ? null : onGrant,
                child: requesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_anyPermanentlyDenied
                        ? l.permissionOpenSettings
                        : l.permissionGrant),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: requesting ? null : onLater,
                child: Text(
                  l.permissionLater,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppPermissionKind kind) => switch (kind) {
        AppPermissionKind.camera => Icons.camera_alt_rounded,
        AppPermissionKind.microphone => Icons.mic_rounded,
        AppPermissionKind.location => Icons.location_on_rounded,
        AppPermissionKind.notification => Icons.notifications_rounded,
      };

  String _labelFor(AppLocalizations l, AppPermissionKind kind) =>
      switch (kind) {
        AppPermissionKind.camera => l.permissionCamera,
        AppPermissionKind.microphone => l.permissionMicrophone,
        AppPermissionKind.location => l.permissionLocation,
        AppPermissionKind.notification => l.permissionNotification,
      };
}
