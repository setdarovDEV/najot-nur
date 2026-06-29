import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/observation_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/score_ring.dart';

class ObservationResultScreen extends ConsumerWidget {
  const ObservationResultScreen({super.key, required this.attempt});
  final ObservationAttempt attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final byCategory =
        (attempt.analysis['by_category'] as Map?)?.cast<String, dynamic>() ?? {};
    final catLabels = {
      'psychology': l.catPsychology,
      'body_language': l.catBodyLanguage,
      'observation': l.catObservation,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.observationAnalysis)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ScoreRing(
                score: attempt.score ?? 0, size: 150, label: l.scoreOverallLabel),
          ),
          const SizedBox(height: 24),
          if (attempt.summary != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.wine100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(attempt.summary!,
                  style: const TextStyle(height: 1.5, color: AppColors.ink)),
            ),
          if (byCategory.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l.byDirections,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...byCategory.entries.where((e) => '${e.value}'.isNotEmpty).map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(catLabels[e.key] ?? e.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.wine)),
                        const SizedBox(height: 6),
                        Text('${e.value}',
                            style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                ),
          ],
          if (attempt.strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ListBlock(
                title: l.strengthsTitle,
                items: attempt.strengths,
                color: AppColors.success),
          ],
          if (attempt.improvements.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ListBlock(
                title: l.improvementsTitle,
                items: attempt.improvements,
                color: AppColors.warning),
          ],
          if (!isLoggedIn) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.wineGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.loginRequiredTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.loginRequiredSubtitle,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.wine,
                    ),
                    onPressed: () => context.push('/auth'),
                    child: Text(l.registerLogin),
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
  const _ListBlock(
      {required this.title, required this.items, required this.color});
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
