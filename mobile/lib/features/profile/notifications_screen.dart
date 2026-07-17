import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Notifications, Liquid Glass mockup "8a": glass rows with icon chips and
/// audience pill, staggered entrances over the ambient orbs.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
    final list = ref.watch(notificationsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          list.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
            data: (items) => RefreshIndicator(
              color: AppColors.wine,
              onRefresh: () async => ref.invalidate(notificationsProvider),
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
                              l.notifications,
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
                          icon: Icons.notifications_none_rounded,
                          message: l.noNotifications,
                        ),
                      )
                    else
                      for (var i = 0; i < items.length; i++) ...[
                        GlassEntrance(
                          delay: GlassMotion.entranceStep * (1 + i),
                          child: _NotificationCard(n: items[i]),
                        ),
                        const SizedBox(height: 10),
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
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.notifications),
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.n});
  final AppNotification n;

  String _date(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  String _audienceLabel(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (n.audience) {
      'user' => l.audiencePersonal,
      'course' => l.audienceCourse,
      _ => l.audienceAll,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final chipBg =
        dark ? AppColors.wine300.withValues(alpha: 0.16) : AppColors.wine100;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                _date(n.createdAt),
                style: TextStyle(color: mutedColor, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            n.body,
            style: TextStyle(
              color: dark
                  ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
                  : AppColors.inkSoft,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _audienceLabel(context),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
