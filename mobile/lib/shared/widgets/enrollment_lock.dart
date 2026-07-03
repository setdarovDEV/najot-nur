import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';

enum EnrollmentLockReason {
  practicum,
  quiz,
  observation,
  generic,
}

class EnrollmentStatus {
  const EnrollmentStatus({required this.hasActiveEnrollment, required this.isStaff});
  final bool hasActiveEnrollment;
  final bool isStaff;

  factory EnrollmentStatus.fromJson(Map<String, dynamic> json) {
    return EnrollmentStatus(
      hasActiveEnrollment: json['has_active_enrollment'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
    );
  }
}

final enrollmentStatusProvider =
    FutureProvider.autoDispose<EnrollmentStatus>((ref) async {
  final api = ref.watch(apiClientProvider);
  final r = await api.dio.get('/courses/me/enrollment-status');
  return EnrollmentStatus.fromJson(r.data as Map<String, dynamic>);
});

class EnrollmentLock extends ConsumerWidget {
  const EnrollmentLock({super.key, required this.reason});
  final EnrollmentLockReason reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final copy = _copy(l, reason);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.wine.withValues(alpha: 0.12),
                    AppColors.wine.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.wine.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: AppColors.wine.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              copy.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),

            // Body
            Text(
              copy.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),

            // CTA button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/home'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.school_outlined, color: Colors.white, size: 20),
                label: Text(
                  copy.cta,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _LockCopy _copy(AppLocalizations l, EnrollmentLockReason reason) {
    switch (reason) {
      case EnrollmentLockReason.practicum:
        return _LockCopy(
          title: 'Praktikumlar faqat kurs egalari uchun',
          body:
              'Ekspert ovozi bilan amaliy mashqlardan foydalanish uchun avval '
              'kurs sotib oling. Kurs tugagach, barcha praktikumlar avtomatik '
              'ochiladi.',
          cta: 'Kurslarni ko\'rish',
        );
      case EnrollmentLockReason.quiz:
        return _LockCopy(
          title: 'Testlar faqat kurs egalari uchun',
          body:
              'Rasm va video asosidagi psixologik testlardan foydalanish uchun '
              'avval kurs sotib oling. Kurs tugagach, barcha testlar avtomatik '
              'ochiladi.',
          cta: 'Kurslarni ko\'rish',
        );
      case EnrollmentLockReason.observation:
        return _LockCopy(
          title: 'Kuzatuvchanlik testi faqat kurs egalari uchun',
          body:
              '10 ta video/rasm asosidagi kuzatuvchanlik testidan foydalanish '
              'uchun avval kurs sotib oling. Kurs tugagach, barcha testlar '
              'avtomatik ochiladi.',
          cta: 'Kurslarni ko\'rish',
        );
      case EnrollmentLockReason.generic:
        return _LockCopy(
          title: 'Bu bo\'lim faqat kurs egalari uchun',
          body:
              'Ushbu bo\'limdan foydalanish uchun avval kurs sotib oling. '
              'Kurs tugagach, barcha amaliy mashqlar avtomatik ochiladi.',
          cta: 'Kurslarni ko\'rish',
        );
    }
  }
}

class _LockCopy {
  const _LockCopy({required this.title, required this.body, required this.cta});
  final String title;
  final String body;
  final String cta;
}
