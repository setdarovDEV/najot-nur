import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

class AnalysisHistoryScreen extends ConsumerWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (!ref.watch(authControllerProvider).isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.analysisHistory),
        titleSpacing: 20,
      ),
      body: history.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(historyProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ErrorView(message: l.noHistory);
          }
          return RefreshIndicator(
            color: AppColors.wine,
            onRefresh: () async => ref.invalidate(historyProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _HistoryCard(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final HistoryItem item;

  Color _badgeColor() => switch (item.kind) {
        HistoryKind.speech => AppColors.wine,
        HistoryKind.voice => AppColors.blue,
        HistoryKind.observation => AppColors.orange,
      };

  IconData _icon() => switch (item.kind) {
        HistoryKind.speech => Icons.record_voice_over_rounded,
        HistoryKind.voice => Icons.graphic_eq_rounded,
        HistoryKind.observation => Icons.visibility_rounded,
      };

  String _title(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (item.kind) {
      HistoryKind.speech => l.historySpeech,
      HistoryKind.voice => l.voiceAnalysis,
      HistoryKind.observation => l.historyObservation,
    };
  }

  String _kindLabel(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (item.kind) {
      HistoryKind.speech => l.historySpeech,
      HistoryKind.voice => l.voiceAnalysis,
      HistoryKind.observation => l.historyObservation,
    };
  }

  String? _subtitle(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (item.kind == HistoryKind.speech &&
        item.meaningScore != null &&
        item.fluencyScore != null) {
      return l.meaningFluency(item.meaningScore!, item.fluencyScore!);
    }
    return item.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor();
    final subtitle = _subtitle(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _title(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _kindLabel(context),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatDate(item.createdAt),
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (item.score != null)
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.wine,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${item.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}  $hh:$mi';
  }
}
