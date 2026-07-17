import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/practicum_models.dart';
import '../../models/quiz_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/enrollment_lock.dart';

/// Tests tab, Liquid Glass mockup "5a": in-scroll large title, uppercase
/// section eyebrows and glass rows with icon chips for quizzes and
/// practicums. Data still comes from [quizzesProvider]/[practicumsProvider]
/// and navigation is unchanged.
class QuizzesTab extends ConsumerStatefulWidget {
  const QuizzesTab({super.key});

  @override
  ConsumerState<QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends ConsumerState<QuizzesTab> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const AmbientOrbs(),
            _LoginGate(l: l),
          ],
        ),
      );
    }

    final enrollment = ref.watch(enrollmentStatusProvider);
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
          NotificationListener<ScrollNotification>(
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
                        l.testsTitle,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Viktorinalar va psixologik testlar',
                        style: TextStyle(fontSize: 12.5, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 12),
                  GlassEntrance(
                    delay: GlassMotion.entranceStep,
                    child: _ViewModeBanner(
                      onTap: () => context.go('/home'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GlassEntrance(
                  delay: GlassMotion.entranceStep,
                  child: _PsychologyCard(
                    onTap: () => context.push('/psychology'),
                  ),
                ),
                const SizedBox(height: 18),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 2,
                  child: _SectionEyebrow('Testlar'.toUpperCase()),
                ),
                const SizedBox(height: 10),
                ..._buildQuizzes(context, l),
                const SizedBox(height: 18),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 3,
                  child: _SectionEyebrow('Praktikumlar'.toUpperCase()),
                ),
                const SizedBox(height: 10),
                ..._buildPracticums(context, l, isLocked),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(offset: _scrollOffset, title: l.testsTitle),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuizzes(BuildContext context, AppLocalizations l) {
    final quizzesAsync = ref.watch(quizzesProvider);
    return quizzesAsync.when(
      loading: () => const [
        Padding(padding: EdgeInsets.symmetric(vertical: 24), child: AppLoader()),
      ],
      error: (e, _) => [
        ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(quizzesProvider),
        ),
      ],
      data: (list) {
        if (list.isEmpty) {
          return [
            _SectionEmpty(icon: Icons.quiz_outlined, message: l.noQuizzes),
          ];
        }
        return [
          for (var i = 0; i < list.length; i++) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep * (2 + i),
              child: _QuizCard(quiz: list[i]),
            ),
            const SizedBox(height: 10),
          ],
        ];
      },
    );
  }

  List<Widget> _buildPracticums(
      BuildContext context, AppLocalizations l, bool isLocked) {
    final practicumsAsync = ref.watch(practicumsProvider);
    return practicumsAsync.when(
      loading: () => const [
        Padding(padding: EdgeInsets.symmetric(vertical: 24), child: AppLoader()),
      ],
      error: (e, _) => [
        ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(practicumsProvider),
        ),
      ],
      data: (list) {
        final approved = list.where((p) => p.status == 'approved').toList();
        if (approved.isEmpty) {
          return [
            _SectionEmpty(
              icon: Icons.headphones_outlined,
              message: l.noPracticums,
            ),
          ];
        }
        return [
          for (var i = 0; i < approved.length; i++) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep * (4 + i),
              child: _PracticumCard(
                practicum: approved[i],
                isLocked: isLocked,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ];
      },
    );
  }
}

// ───────────────────────── Section pieces ─────────────────────────

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: mutedColor,
        ),
      ),
    );
  }
}

class _ViewModeBanner extends StatelessWidget {
  const _ViewModeBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: AppColors.radiusSegment,
        withShadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: accent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Ko'rish rejimi — topshirish uchun kurs kerak",
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accent),
          ],
        ),
      ),
    );
  }
}

class _LoginGate extends StatelessWidget {
  const _LoginGate({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassEntrance(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark
                        ? AppColors.wine300.withValues(alpha: 0.16)
                        : AppColors.wine.withValues(alpha: 0.10),
                  ),
                  child: Icon(Icons.quiz_outlined, size: 28, color: accent),
                ),
                const SizedBox(height: 14),
                Text(
                  l.loginRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                GlassPressable(
                  onTap: () => context.push('/auth'),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.wineGradient,
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusButton),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wine.withValues(alpha: 0.30),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Text(
                      l.loginRequiredBtn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact inline empty state for a section — same fixed height for both
/// the quizzes and practicums sections so empty blocks always match.
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: dark
                  ? AppColors.wine300.withValues(alpha: 0.16)
                  : AppColors.wine.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Cards ─────────────────────────

/// Featured psychology-test card (mockup 5a's highlighted result card slot):
/// orange-tinted icon, title + subtitle, chevron — routes to the existing
/// /psychology flow.
class _PsychologyCard extends StatelessWidget {
  const _PsychologyCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PSIXOLOGIK TEST',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: AppColors.orange, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.psychologyTest,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.psychologyTestSub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: mutedColor, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});
  final QuizSummary quiz;

  Color _diffColor() {
    switch (quiz.difficulty) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _diffLabel(AppLocalizations l) {
    switch (quiz.difficulty) {
      case 'easy':
        return l.quizEasy;
      case 'hard':
        return l.quizHard;
      default:
        return l.quizMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassPressable(
      onTap: () => context.push('/quizzes/${quiz.id}'),
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        withShadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: dark
                    ? AppColors.wine300.withValues(alpha: 0.16)
                    : AppColors.wine.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.quiz_rounded, color: accent, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      l.quizQuestions(quiz.questionCount),
                      if (quiz.videoUrl != null) 'Video',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _diffColor().withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _diffLabel(l),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: _diffColor(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PracticumCard extends StatelessWidget {
  const _PracticumCard({required this.practicum, required this.isLocked});
  final Practicum practicum;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: () => context.push('/practicums/${practicum.id}'),
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        withShadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.headphones_rounded,
                  color: AppColors.blue, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    practicum.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  if (practicum.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      practicum.category!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: mutedColor),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.chevron_right_rounded,
              color: mutedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
