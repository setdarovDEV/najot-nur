import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Payment history, Liquid Glass mockup "8d": a glass summary card with the
/// total spent, then glass order rows with amount + status pill.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
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
    final orders = ref.watch(myOrdersProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          orders.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(myOrdersProvider),
            ),
            data: (items) => RefreshIndicator(
              color: AppColors.wine,
              onRefresh: () async => ref.invalidate(myOrdersProvider),
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
                              l.myOrders,
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
                          icon: Icons.receipt_long_rounded,
                          message: l.noOrders,
                        ),
                      )
                    else ...[
                      GlassEntrance(
                        delay: GlassMotion.entranceStep,
                        child: _SummaryCard(orders: items),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < items.length; i++) ...[
                        GlassEntrance(
                          delay: GlassMotion.entranceStep * (2 + i),
                          child: _OrderCard(order: items[i]),
                        ),
                        const SizedBox(height: 12),
                      ],
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
            child: GlassTopChrome(offset: _scrollOffset, title: l.myOrders),
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

/// "Jami sarflangan" glass card — totals only approved orders.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.orders});
  final List<OrderRequest> orders;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    final approved =
        orders.where((o) => o.status == OrderStatus.approved).toList();
    final total = approved.fold<num>(0, (sum, o) => sum + o.amount);
    final pendingCount =
        orders.where((o) => o.status == OrderStatus.pending).length;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JAMI SARFLANGAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${_formatAmount(total)} so'm",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.wine300.withValues(alpha: 0.16)
                      : AppColors.wine100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "${approved.length} ta to'lov",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Kutilmoqda: $pendingCount',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderRequest order;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final statusColor = _statusColor(order.status);
    final statusLabel = _statusLabel(l, order.status);
    final typeLabel = order.purpose == OrderPurpose.audiobook
        ? l.orderTypeAudiobook
        : l.orderTypeCourse;
    final typeIcon = order.purpose == OrderPurpose.audiobook
        ? Icons.menu_book_rounded
        : Icons.school_rounded;

    final date = _formatDate(order.createdAt);

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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.wine300.withValues(alpha: 0.16)
                      : AppColors.wine100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(typeIcon,
                    color: dark ? AppColors.wine300 : AppColors.wine,
                    size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.targetTitle ?? typeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$typeLabel · $date · ${_methodLabel(l, order.paymentMethod)}',
                      style: TextStyle(color: mutedColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(order.amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (order.adminNote != null && order.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.wine.withValues(alpha: dark ? 0.16 : 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16,
                      color: dark ? AppColors.wine300 : AppColors.wine),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.adminNote!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: dark
                            ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
                            : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (order.status == OrderStatus.approved &&
              order.purpose == OrderPurpose.course &&
              order.courseId != null) ...[
            const SizedBox(height: 12),
            _GoToCourseButton(courseId: order.courseId!),
          ],
          if (order.status == OrderStatus.pending) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 14, color: AppColors.warning),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Admin ko\'rib chiqilmoqda. Tasdiqlanganda kurs ochiladi.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.approved:
        return AppColors.success;
      case OrderStatus.rejected:
        return AppColors.danger;
      case OrderStatus.pending:
        return AppColors.warning;
    }
  }

  String _statusLabel(AppLocalizations l, OrderStatus s) {
    switch (s) {
      case OrderStatus.approved:
        return l.orderStatusApproved;
      case OrderStatus.rejected:
        return l.orderStatusRejected;
      case OrderStatus.pending:
        return l.orderStatusPending;
    }
  }

  String _methodLabel(AppLocalizations l, OrderPaymentMethod m) {
    switch (m) {
      case OrderPaymentMethod.uzum:
        return l.methodUzum;
      case OrderPaymentMethod.uzumNasiya:
        return l.methodUzumNasiya;
      case OrderPaymentMethod.cash:
        return l.methodCash;
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}

String _formatAmount(num amount) {
  final s = amount.toStringAsFixed(0);
  final buf = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buf.write(' ');
    buf.write(s[i]);
    count++;
  }
  return buf.toString().split('').reversed.join();
}

class _GoToCourseButton extends StatelessWidget {
  const _GoToCourseButton({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/courses/$courseId/learn'),
        icon: const Icon(Icons.play_circle_rounded, size: 18),
        label: const Text('Kursni boshlash'),
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.radiusSegment)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
