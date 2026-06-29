import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (!ref.watch(authControllerProvider).isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myOrders), titleSpacing: 20),
      body: orders.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              icon: Icons.receipt_long_rounded,
              message: l.noOrders,
            );
          }
          return RefreshIndicator(
            color: AppColors.wine,
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(order: items[i]),
            ),
          );
        },
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
    final statusColor = _statusColor(order.status);
    final statusLabel = _statusLabel(l, order.status);
    final typeLabel = order.purpose == OrderPurpose.audiobook
        ? l.orderTypeAudiobook
        : l.orderTypeCourse;
    final typeIcon = order.purpose == OrderPurpose.audiobook
        ? Icons.menu_book_rounded
        : Icons.school_rounded;

    final date = _formatDate(order.createdAt);
    final amount =
        '${_formatAmount(order.amount)} ${order.currency}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.wine100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: AppColors.wine, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.targetTitle ?? typeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$typeLabel · $date',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoChip(
                icon: Icons.payments_outlined,
                label: amount,
              ),
              const SizedBox(width: 10),
              _InfoChip(
                icon: Icons.credit_card_rounded,
                label: _methodLabel(l, order.paymentMethod),
              ),
            ],
          ),
          if (order.adminNote != null && order.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.wine100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.wine),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.adminNote!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.inkSoft),
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
            Row(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Admin ko\'rib chiqilmoqda. Tasdiqlanganda kurs ochiladi.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
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
      case OrderPaymentMethod.payme:
        return l.methodPayme;
      case OrderPaymentMethod.cash:
        return l.methodCash;
      case OrderPaymentMethod.click:
        return l.methodClick;
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
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
}

class _GoToCourseButton extends StatelessWidget {
  const _GoToCourseButton({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/courses/$courseId/learn'),
        icon: const Icon(Icons.play_circle_rounded, size: 18),
        label: const Text('Kursni boshlash'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.wine,
          side: const BorderSide(color: AppColors.wine),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
      ],
    );
  }
}
