import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Analysis history, Liquid Glass style: ambient orbs, glass back header and
/// frosted history rows with kind-tinted icon chips + score badge.
class AnalysisHistoryScreen extends ConsumerStatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  ConsumerState<AnalysisHistoryScreen> createState() =>
      _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends ConsumerState<AnalysisHistoryScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!ref.watch(authControllerProvider).isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }
    final history = ref.watch(historyProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          history.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(historyProvider),
            ),
            data: (items) => RefreshIndicator(
              color: AppColors.wine,
              onRefresh: () async => ref.invalidate(historyProvider),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis == Axis.vertical) {
                    _scrollOffset.value = n.metrics.pixels;
                  }
                  return false;
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 60),
                  children: [
                    GlassEntrance(
                      child: Row(
                        children: [
                          _GlassBackButton(onTap: () => context.pop()),
                          Expanded(
                            child: Text(
                              l.analysisHistory,
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
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: EmptyView(
                          icon: Icons.history_rounded,
                          message: l.noHistory,
                        ),
                      )
                    else
                      for (var i = 0; i < items.length; i++) ...[
                        GlassEntrance(
                          delay: GlassMotion.entranceStep * (1 + i),
                          child: _HistoryCard(item: items[i]),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(
                offset: _scrollOffset, title: l.analysisHistory),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
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
          Icons.arrow_back_rounded,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final HistoryItem item;

  Color _badgeColor(bool dark) => switch (item.kind) {
        HistoryKind.speech => dark ? AppColors.wine300 : AppColors.wine,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final color = _badgeColor(dark);
    final subtitle = _subtitle(context);

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mutedColor, fontSize: 11.5),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(color: mutedColor, fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (item.score != null) ...[
            const SizedBox(width: 10),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.wineGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
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
