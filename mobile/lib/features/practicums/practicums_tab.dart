import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/enrollment_lock.dart';
import 'practicum_card.dart';

/// Practicums tab, Liquid Glass tab pattern (courses tab, mockup "2a"):
/// ambient orbs, large in-scroll title, scroll-reactive top chrome and glass
/// practicum cards. Enrollment gating and list data are unchanged.
class PracticumsTab extends ConsumerStatefulWidget {
  const PracticumsTab({super.key});

  @override
  ConsumerState<PracticumsTab> createState() => _PracticumsTabState();
}

class _PracticumsTabState extends ConsumerState<PracticumsTab> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final enrollment = ref.watch(enrollmentStatusProvider);
    final practicumsAsync = ref.watch(practicumsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    final isLocked = enrollment.when(
      loading: () => false,
      error: (_, __) => false,
      data: (s) => !s.hasActiveEnrollment && !s.isStaff,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AmbientOrbs(),
          practicumsAsync.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: l.errorPrefix(e.toString()),
              onRetry: () => ref.invalidate(practicumsProvider),
            ),
            data: (list) {
              final approved =
                  list.where((p) => p.status == 'approved').toList();
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis == Axis.vertical) {
                    _scrollOffset.value = n.metrics.pixels;
                  }
                  return false;
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 150),
                  children: [
                    GlassEntrance(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.practicumsTitle,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.practicumsSubtitle,
                            style:
                                TextStyle(fontSize: 12.5, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isLocked) ...[
                      const GlassEntrance(
                        delay: GlassMotion.entranceStep,
                        child: _PreviewBanner(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (approved.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyView(
                          icon: Icons.headphones_outlined,
                          message: l.noPracticums,
                        ),
                      )
                    else
                      for (var i = 0; i < approved.length; i++) ...[
                        GlassEntrance(
                          delay: GlassMotion.entranceStep * (2 + i),
                          child: PracticumInlineCard(
                            practicum: approved[i],
                            isLocked: isLocked,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(
                offset: _scrollOffset, title: l.practicumsTitle),
          ),
        ],
      ),
    );
  }
}

/// "Kurs sotib olib to'liq foydalaning" — glass preview banner for
/// non-enrolled users.
class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassPressable(
      onTap: () => context.go('/home'),
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        withShadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dark
                    ? AppColors.wine300.withValues(alpha: 0.16)
                    : AppColors.wine.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kurs sotib olib to'liq foydalaning",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Hozir ko'rish rejimida. Yozish va AI tahlil uchun kurs kerak.",
                    style: TextStyle(color: mutedColor, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
          ],
        ),
      ),
    );
  }
}
