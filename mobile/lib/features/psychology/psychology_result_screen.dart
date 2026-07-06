import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/psychology_models.dart';
import '../../providers/providers.dart';

class PsychologyResultScreen extends ConsumerStatefulWidget {
  const PsychologyResultScreen({super.key, required this.attempt});
  final PsychologyAttempt attempt;

  @override
  ConsumerState<PsychologyResultScreen> createState() =>
      _PsychologyResultScreenState();
}

class _PsychologyResultScreenState
    extends ConsumerState<PsychologyResultScreen> {
  bool _requesting = false;
  PsychologyAttempt? _attempt;

  @override
  void initState() {
    super.initState();
    _attempt = widget.attempt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(autoRequestAiAfterAuthProvider)) {
        ref.read(autoRequestAiAfterAuthProvider.notifier).state = false;
        _submitAndRequestAi();
      }
    });
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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero card ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 30),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l.psychologyAnalysis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _RingPainter(score / 100),
                        child: Center(
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _gradeTitle(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _gradeSub(context),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Waveform ───────────────────────────────────────────────
                _WaveformCard(),
                const SizedBox(height: 20),

                // ── AI Analysis card ───────────────────────────────────────
                if (hasAi) ...[
                  _SectionTitle(l.psychologyAnalysis),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.wine.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: AppColors.wine, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'AI tahlil',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.wine,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          attempt.aiAnalysis!,
                          style: const TextStyle(
                              height: 1.6, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Strengths ──────────────────────────────────────────────
                if (attempt.strengths.isNotEmpty) ...[
                  _SectionTitle(l.strengthsTitle),
                  const SizedBox(height: 8),
                  ...attempt.strengths.map(
                    (s) => _BulletRow(text: s, color: AppColors.success),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Improvements ───────────────────────────────────────────
                if (attempt.improvements.isNotEmpty) ...[
                  _SectionTitle(l.improvementsTitle),
                  const SizedBox(height: 8),
                  ...attempt.improvements.map(
                    (s) => _BulletRow(text: s, color: AppColors.warning),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Request AI (unauthenticated) ───────────────────────────
                if (!isLoggedIn) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.wineGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.psychologyAiTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.psychologyAiSubtitle,
                          style: const TextStyle(
                              color: Colors.white70, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.wine,
                          ),
                          onPressed: _requesting ? null : _goToAuth,
                          child: _requesting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: AppColors.wine,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Text(l.registerLogin),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (!hasAi) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.wine.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: AppColors.wine, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l.psychologyAnalysis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.wine,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.psychologyAiSubtitle,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _requesting ? null : _requestAi,
                          icon: _requesting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(
                              _requesting ? l.analyzing : l.analyze),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.wine,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Back button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.wine),
                      foregroundColor: AppColors.wine,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(l.backToHome),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Local widgets ────────────────────────────────────────────────────────────

class _WaveformCard extends StatelessWidget {
  static const _heights = [
    0.3, 0.6, 0.9, 0.5, 1.0, 0.4, 0.7, 0.8, 0.5, 0.3,
    0.6, 0.9, 0.4, 0.7, 0.5, 1.0, 0.6, 0.4, 0.8, 0.5,
    0.3, 0.7, 0.9, 0.4, 0.6, 0.8, 0.5, 0.7, 0.9, 0.4,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights.map((h) {
          return Container(
            width: 4,
            height: 40 * h,
            decoration: BoxDecoration(
              color: AppColors.wine.withValues(alpha: 0.6 + h * 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      );
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
