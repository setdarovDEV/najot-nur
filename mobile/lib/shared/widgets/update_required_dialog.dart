import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/app_version.dart';
import '../../providers/providers.dart';

/// Full-screen blocking dialog shown when the installed build is below
/// the server's `min_supported_version` (or the server has flipped the
/// global `force_update` switch).
///
/// Wraps its child in a [Stack] so the caller can drop it in anywhere
/// — typically right above the security watermark inside
/// `MaterialApp.builder`. When the version check resolves and says
/// "you must update", we render a scrim + a centred card with a single
/// "Update" button that opens the Play Store. For non-forced updates
/// a secondary "Later" button lets the user keep using the app for
/// now (this branch is rare — only when the server says there's a
/// newer build but the current one is still supported).
class UpdateRequiredDialog extends ConsumerWidget {
  const UpdateRequiredDialog({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appVersionProvider).valueOrNull;
    if (config == null) return child;
    return _maybeWrap(context, ref, config);
  }

  Widget _maybeWrap(
    BuildContext context,
    WidgetRef ref,
    AppVersionConfig config,
  ) {
    return Stack(
      children: [
        child,
        // Read the running version off PackageInfo via the provider; if
        // we can't read it (e.g. platform channel not available in
        // tests) fall back to "0.0.0" so the dialog still appears and
        // doesn't silently break the app.
        _BlockingOverlay(
          config: config,
          currentVersion: ref.watch(installedVersionProvider).valueOrNull,
        ),
      ],
    );
  }
}

class _BlockingOverlay extends StatelessWidget {
  const _BlockingOverlay({required this.config, required this.currentVersion});
  final AppVersionConfig config;
  final String? currentVersion;

  @override
  Widget build(BuildContext context) {
    final installed = currentVersion ?? '0.0.0';
    final needsUpdate = config.requiresUpdate(installed) ||
        config.hasOptionalUpdate(installed);
    if (!needsUpdate) return const SizedBox.shrink();
    final forced = config.requiresUpdate(installed);
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _UpdateCard(config: config, forced: forced),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.config, required this.forced});
  final AppVersionConfig config;
  final bool forced;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(config.updateUrl);
    if (uri == null) return;
    // externalApplication is required on iOS 9+ to leave the app and
    // hand off to the Play Store / browser.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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
                  Icons.system_update_alt_rounded,
                  size: 32,
                  color: AppColors.wine,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.updateRequiredTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              config.message.isNotEmpty
                  ? config.message
                  : l.updateRequiredMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
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
                onPressed: () => _open(context),
                child: Text(l.updateNow),
              ),
            ),
            if (!forced) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(
                    l.updateLater,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
