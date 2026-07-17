import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/psychology_models.dart';
import '../../providers/providers.dart';

/// Psychology result, Liquid Glass mockup "6e"/"3d" language: animated score
/// ring, glass section cards for the AI analysis / strengths / improvements
/// and a gradient auth CTA. Submit/AI-request logic is unchanged.
class PsychologyResultScreen extends ConsumerStatefulWidget {
  const PsychologyResultScreen({super.key, required this.attempt});
  final PsychologyAttempt attempt;

  @override
  ConsumerState<PsychologyResultScreen> createState() =>
      _PsychologyResultScreenState();
}

class _PsychologyResultScreenState
    extends ConsumerState<PsychologyResultScreen>
    with SingleTickerProviderStateMixin {
  bool _requesting = false;
  PsychologyAttempt? _attempt;

  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _attempt = widget.attempt;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ring.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(autoRequestAiAfterAuthProvider)) {
        ref.read(autoRequestAiAfterAuthProvider.notifier).state = false;
        _submitAndRequestAi();
      }
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  /// Re-submits a local attempt to the server then requests AI analysis.
  /// Used when the user logs in after completing the test without an account.
  Future<void> _submitAndRequestAi() async {
    final l = AppLocalizations.of(context);
    setState(() => _requesting = true);
    try {
      PsychologyAttempt serverAttempt;
      if (_attempt!.id.startsWith('local-')) {
        serverAttempt = await ref
            .read(psychologyRepositoryProvider)
            .submit(_attempt!.answers);
      } else {
        serverAttempt = _attempt!;
      }
      final withAi = await ref
          .read(psychologyRepositoryProvider)
          .requestAi(serverAttempt.id);
      if (!mounted) return;
      setState(() => _attempt = withAi);
      ref.read(pendingPsychologyAttemptProvider.notifier).state = null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.errorPrefix(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _requestAi() async {
    final l = AppLocalizations.of(context);
    setState(() => _requesting = true);
    try {
      if (_attempt!.id.startsWith('local-')) {
        _goToAuth();
        return;
      }
      final updated =
          await ref.read(psychologyRepositoryProvider).requestAi(_attempt!.id);
      if (!mounted) return;
      setState(() => _attempt = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.errorPrefix(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _goToAuth() {
    ref.read(pendingPsychologyAttemptProvider.notifier).state = _attempt;
    ref.read(autoRequestAiAfterAuthProvider.notifier).state = true;
    ref.read(pendingReturnPathProvider.notifier).state = '/psychology/result';
    context.push('/auth');
  }

  String _gradeTitle(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _attempt!.score ?? 0;
    if (s >= 85) return l.gradeTitleExcellent;
    if (s >= 70) return l.gradeTitleGood;
    if (s >= 50) return l.gradeTitleAverage;
    return l.gradeTitleWeak;
  }

  String _gradeSub(BuildContext context) {
    final l = AppLocalizations.of(context);
    final attempt = _attempt!;
    if (attempt.summary != null && attempt.summary!.isNotEmpty) {
      return attempt.summary!;
    }
    return l.psychologyScoreLabel;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final attempt = _attempt!;
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final hasAi = attempt.aiAnalysis != null && attempt.aiAnalysis!.isNotEmpty;
    final score = attempt.score ?? 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    final ringColor = score >= 70 ? AppColors.success : AppColors.warning;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          ListView(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16,
                MediaQuery.of(context).padding.bottom + 24),
            children: [
              GlassEntrance(
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.go('/home'),
                    ),
                    Expanded(
                      child: Text(
                        l.psychologyAnalysis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Animated score ring (mockup 6e).
              GlassEntrance(
                delay: GlassMotion.entranceStep,
                child: Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: AnimatedBuilder(
                      animation: _ring,
                      builder: (context, _) => CustomPaint(
                        painter: _ScoreRingPainter(
                          progress:
                              Curves.easeOutCubic.transform(_ring.value) *
                                  (score / 100),
                          color: ringColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$score',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                l.psychologyScoreLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassEntrance(
                delay: GlassMotion.entranceStep * 2,
                child: Column(
                  children: [
                    Text(
                      _gradeTitle(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _gradeSub(context),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, height: 1.5, color: mutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassEntrance(
                delay: GlassMotion.entranceStep * 3,
                child: const _WaveformCard(),
              ),
              const SizedBox(height: 14),

              // ── AI Analysis card ───────────────────────────────────────
              if (hasAi)
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 4,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AiCard(
                      title: 'AI tahlil',
                      child: Text(
                        attempt.aiAnalysis!,
                        style: TextStyle(
                          height: 1.6,
                          fontSize: 13.5,
                          color: dark
                              ? AppColors.inkDarkPrimary
                                  .withValues(alpha: 0.86)
                              : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Strengths ──────────────────────────────────────────────
              if (attempt.strengths.isNotEmpty)
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 5,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ListCard(
                      title: l.strengthsTitle,
                      items: attempt.strengths,
                      color: AppColors.success,
                    ),
                  ),
                ),

              // ── Improvements ───────────────────────────────────────────
              if (attempt.improvements.isNotEmpty)
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 6,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ListCard(
                      title: l.improvementsTitle,
                      items: attempt.improvements,
                      color: AppColors.warning,
                    ),
                  ),
                ),

              // ── Request AI (unauthenticated) ───────────────────────────
              if (!isLoggedIn)
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 7,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AuthCtaCard(
                      title: l.psychologyAiTitle,
                      subtitle: l.psychologyAiSubtitle,
                      buttonLabel: l.registerLogin,
                      loading: _requesting,
                      onTap: _goToAuth,
                    ),
                  ),
                )
              else if (!hasAi)
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 7,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AiCard(
                      title: l.psychologyAnalysis,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.psychologyAiSubtitle,
                            style:
                                TextStyle(color: mutedColor, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          _PrimaryCta(
                            label: _requesting ? l.analyzing : l.analyze,
                            loading: _requesting,
                            onTap: _requesting ? null : _requestAi,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Back button ─────────────────────────────────────────────
              GlassEntrance(
                delay: GlassMotion.entranceStep * 8,
                child: GlassPressable(
                  onTap: () => context.go('/home'),
                  child: GlassContainer(
                    borderRadius: AppColors.radiusButton,
                    height: 54,
                    withShadow: false,
                    alignment: Alignment.center,
                    child: Text(
                      l.backToHome,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark
                            ? AppColors.inkDarkPrimary
                            : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Local widgets ────────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AppColors.glassFillDark : AppColors.glassFillLight,
          border: Border.all(
            color:
                dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: loading ? null : onTap,
      child: Opacity(
        opacity: onTap == null && !loading ? 0.5 : 1,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.wineGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusButton),
            boxShadow: [
              BoxShadow(
                color: AppColors.wine.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Glass card with the sparkle icon header used for AI sections.
class _AiCard extends StatelessWidget {
  const _AiCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.wine300.withValues(alpha: 0.16)
                      : AppColors.wine.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: accent, size: 19),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.items,
    required this.color,
  });
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final bodyColor = dark
        ? AppColors.inkDarkPrimary.withValues(alpha: 0.82)
        : AppColors.inkSoft;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                          height: 1.5, fontSize: 13, color: bodyColor),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Gradient auth CTA card (brand wine — same in both modes).
class _AuthCtaCard extends StatelessWidget {
  const _AuthCtaCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.loading,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.wineGradient,
        borderRadius: BorderRadius.circular(AppColors.radiusTariffCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          GlassPressable(
            onTap: loading ? null : onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppColors.radiusSegment),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: AppColors.wine),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: AppColors.wine,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformCard extends StatelessWidget {
  const _WaveformCard();

  static const _heights = [
    0.3, 0.6, 0.9, 0.5, 1.0, 0.4, 0.7, 0.8, 0.5, 0.3,
    0.6, 0.9, 0.4, 0.7, 0.5, 1.0, 0.6, 0.4, 0.8, 0.5,
    0.3, 0.7, 0.9, 0.4, 0.6, 0.8, 0.5, 0.7, 0.9, 0.4,
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final barColor = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      borderRadius: AppColors.radiusButton,
      withShadow: false,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights.map((h) {
          return Container(
            width: 4,
            height: 40 * h,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.5 + h * 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 11;
    final bg = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
}
