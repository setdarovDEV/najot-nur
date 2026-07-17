import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/security_service.dart';
import 'secure_screen.dart';

/// Black/dark overlay shown the instant the OS reports a screen-capture
/// attempt. The warning is a single, unmovable banner so the user can see
/// that their session is being recorded and decide to stop the activity.
///
/// iOS does not expose a way to actually block the capture, so the best we
/// can do is make the content obviously flagged.
class SecurityCaptureOverlay extends ConsumerWidget {
  const SecurityCaptureOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(securityStatusProvider).valueOrNull;
    final captured = status?.isCaptured ?? false;
    if (!captured) return child;
    // Capture is only *blocked/flagged* on paid video-lesson screens — the
    // rest of the app allows screenshots/recording, so no warning there.
    return ValueListenableBuilder<bool>(
      valueListenable: SecureScreen.protectionActive,
      builder: (context, protected, _) {
        if (!protected) return child;
        return _CaptureWarning(child: child);
      },
    );
  }
}

class _CaptureWarning extends StatelessWidget {
  const _CaptureWarning({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        // Mute sensitive content with a dark scrim. 70% opacity is enough to
        // make text and figures illegible in a screen recording while still
        // letting the user see the warning.
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xCC000000),
            BlendMode.srcOver,
          ),
          child: child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.securityCaptureDetected,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.securityCaptureSubtitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.fiber_manual_record,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
