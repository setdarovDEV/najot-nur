import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/brand.dart';

/// Entry point for unauthenticated users. Two clearly-labelled primary
/// actions — Register and Login — and an optional Telegram shortcut.
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final configAsync = ref.watch(authConfigProvider);
    final telegramEnabled = configAsync.maybeWhen(
      data: (c) => c.telegramLoginEnabled,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.wine),
                ),
              ),
              const Spacer(),
              const Center(child: BrandBadge(size: 96, radius: 26)),
              const SizedBox(height: 28),
              Text(
                l.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.push('/auth/register'),
                child: Text(l.register),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/auth/login'),
                child: Text(l.login),
              ),
              if (telegramEnabled) ...[
                const SizedBox(height: 14),
                OrDivider(label: l.orUse),
                const SizedBox(height: 14),
                TelegramLoginButton(
                  onPressed: () => context.push('/auth/telegram'),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l.termsNotice,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class TelegramLoginButton extends StatelessWidget {
  const TelegramLoginButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF229ED9),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              l.telegramLogin,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}
