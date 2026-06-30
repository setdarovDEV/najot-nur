import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/psychology_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/score_ring.dart';

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
  }

  /// Request the AI analysis for the current attempt. The backend call
  /// requires an authenticated user, so we use the auth events stream to
  /// know when the user has finished logging in and we can re-fetch.
  Future<void> _requestAi() async {
    final l = AppLocalizations.of(context);
    setState(() => _requesting = true);
    try {
      // If the attempt is local (no backend), we can't call the API yet —
      // show a friendly message and route the user to login.
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
    // Remember where the user came from so the auth flow can drop them
    // back here after a successful login.
    ref.read(pendingReturnPathProvider.notifier).state =
        '/psychology/result';
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final attempt = _attempt!;
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final hasAi = attempt.aiAnalysis != null && attempt.aiAnalysis!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.psychologyAnalysis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ScoreRing(
              score: attempt.score ?? 0,
              size: 150,
              label: l.scoreOverallLabel,
            ),
          ),
          const SizedBox(height: 24),
          if (attempt.summary != null && attempt.summary!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.wine100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                attempt.summary!,
                style: const TextStyle(height: 1.5, color: AppColors.ink),
              ),
            ),
          if (hasAi) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
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
                        l.psychologyAnalysis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.wine,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    attempt.aiAnalysis!,
                    style: const TextStyle(height: 1.5, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ],
          if (attempt.strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ListBlock(
              title: l.strengthsTitle,
              items: attempt.strengths,
              color: AppColors.success,
            ),
          ],
          if (attempt.improvements.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ListBlock(
              title: l.improvementsTitle,
              items: attempt.improvements,
              color: AppColors.warning,
            ),
          ],
          // AI analysis is gated behind authentication.
          if (!isLoggedIn) ...[
            const SizedBox(height: 24),
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
                    style: const TextStyle(color: Colors.white70, height: 1.4),
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
          ] else if (!hasAi) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
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
                          color: AppColors.wine.withValues(alpha: 0.10),
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
                          fontSize: 16,
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
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      _requesting ? l.analyzing : l.analyze,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => context.go('/home'),
            child: Text(l.backToHome),
          ),
        ],
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({
    required this.title,
    required this.items,
    required this.color,
  });
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 10),
                Expanded(child: Text(s, style: const TextStyle(height: 1.4))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
