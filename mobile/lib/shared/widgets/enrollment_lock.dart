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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.wine.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 44,
                color: AppColors.wine.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              copy.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/courses'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wine,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                copy.cta,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
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
