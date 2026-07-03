import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/enrollment_lock.dart';

class SpeechHubScreen extends ConsumerWidget {
  const SpeechHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    if (auth.isLoggedIn) {
      final enrollment = ref.watch(enrollmentStatusProvider);
      final isEnrolled = enrollment.maybeWhen(
        data: (s) => s.hasActiveEnrollment,
        orElse: () => null,
      );
      if (isEnrolled == false) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.wine,
            elevation: 0,
            title: Text(
              l.speechCheck,
              style: const TextStyle(
                  color: AppColors.wine, fontWeight: FontWeight.w800),
            ),
          ),
          body: const EnrollmentLock(reason: EnrollmentLockReason.generic),
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.speechCheck)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l.speechHubPrompt,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            l.speechHubSub,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          _Option(
            icon: Icons.mic_rounded,
            title: l.voiceCheck,
            description: l.voiceCheckDesc,
            gradient: AppColors.wineGradient,
            onTap: () => context.push('/speech/voice'),
          ),
          const SizedBox(height: 16),
          _Option(
            icon: Icons.forum_rounded,
            title: l.speechAnalysis,
            description: l.speechAnalysisDesc,
            gradient: const LinearGradient(
              colors: [AppColors.blue, Color(0xFF2E9BC4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => context.push('/speech/talk'),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(description,
                      style: const TextStyle(
                          color: AppColors.muted, height: 1.35, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
