import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';

/// Opens the "buy" / "request access" bottom sheet used by both
/// the course detail screen and the audiobook locked gate.
Future<void> showOrderRequestSheet(
  BuildContext context, {
  required OrderPurpose purpose,
  required String targetId,
  required String targetTitle,
  required num amount,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _OrderRequestSheet(
      purpose: purpose,
      targetId: targetId,
      targetTitle: targetTitle,
      amount: amount,
    ),
  );
}

class _OrderRequestSheet extends ConsumerStatefulWidget {
  const _OrderRequestSheet({
    required this.purpose,
    required this.targetId,
    required this.targetTitle,
    required this.amount,
  });

  final OrderPurpose purpose;
  final String targetId;
  final String targetTitle;
  final num amount;

  @override
  ConsumerState<_OrderRequestSheet> createState() => _OrderRequestSheetState();
}

class _OrderRequestSheetState extends ConsumerState<_OrderRequestSheet> {
  OrderPaymentMethod _method = OrderPaymentMethod.cash;
  final _proofCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _proofCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_method == OrderPaymentMethod.uzum ||
          _method == OrderPaymentMethod.uzumNasiya) {
        final provider = _method == OrderPaymentMethod.uzum
            ? 'uzum'
            : 'uzum_nasiya';
        final redirect = await ref.read(learningRepositoryProvider).initiatePayment(
              provider: provider,
              purpose: widget.purpose.apiValue,
              amount: widget.amount,
              courseId: widget.purpose == OrderPurpose.course
                  ? widget.targetId
                  : null,
              audiobookId: widget.purpose == OrderPurpose.audiobook
                  ? widget.targetId
                  : null,
            );
        if (!mounted) return;
        final uri = Uri.tryParse(redirect.redirectUrl);
        if (uri == null) {
          throw Exception("To'lov sahifasiga o'tishda xatolik.");
        }
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) throw Exception("Brauzer ochilmadi.");
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _method == OrderPaymentMethod.uzum
                  ? l.uzumRedirectHint
                  : l.uzumNasiyaRedirectHint,
            ),
            backgroundColor: AppColors.wine,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      await ref.read(learningRepositoryProvider).submitOrder(
            purpose: widget.purpose,
            courseId:
                widget.purpose == OrderPurpose.course ? widget.targetId : null,
            audiobookId: widget.purpose == OrderPurpose.audiobook
                ? widget.targetId
                : null,
            amount: widget.amount,
            method: _method,
            paymentProofUrl: _proofCtrl.text.trim().isEmpty
                ? null
                : _proofCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(myOrdersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.orderSubmitted),
          backgroundColor: AppColors.wine,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Bounce the user to "My orders" so they can see the status.
      context.push('/profile/orders');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    return Padding(
      padding:
          EdgeInsets.fromLTRB(24, 20, 24, 24 + mq.viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.purpose == OrderPurpose.course
                ? l.orderSheetCourseTitle
                : l.orderSheetAudiobookTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.targetTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          // Amount (read-only — pulled from server-side data)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.wine100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.wine.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.amountLabel,
                    style: const TextStyle(
                      color: AppColors.wine,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  l.sumPrice(widget.amount.toStringAsFixed(0)),
                  style: const TextStyle(
                    color: AppColors.wine,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l.paymentMethod,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted)),
          const SizedBox(height: 10),
          _MethodPicker(
            selected: _method,
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: 18),
          if (_method == OrderPaymentMethod.cash)
            _CashInstructions()
          else if (_method == OrderPaymentMethod.uzum)
            _RedirectHintCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Uzum orqali to\'lash',
              body: l.uzumRedirectHint,
              color: const Color(0xFF7B2CBF),
            )
          else
            _RedirectHintCard(
              icon: Icons.credit_card_rounded,
              title: 'Uzum Nasiya orqali to\'lash',
              body: l.uzumNasiyaRedirectHint,
              color: const Color(0xFFFF6B35),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12)),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _method == OrderPaymentMethod.uzum
                    ? const Color(0xFF7B2CBF)
                    : _method == OrderPaymentMethod.uzumNasiya
                        ? const Color(0xFFFF6B35)
                        : AppColors.wine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(
                      _method == OrderPaymentMethod.cash
                          ? "So'rov yuborish"
                          : l.orderSubmit,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _method == OrderPaymentMethod.cash
                  ? 'So\'rov admin tomonidan ko\'rib chiqiladi. Tasdiqlangandan so\'ng kurs avtomatik ochiladi.'
                  : l.orderSheetFooter,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashInstructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_rounded,
                    color: Colors.green, size: 17),
              ),
              const SizedBox(width: 10),
              const Text(
                'Naqd to\'lov tartibi',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Step(
            number: '1',
            text: 'Quyidagi tugmani bosib so\'rov yuboring',
          ),
          const SizedBox(height: 8),
          _Step(
            number: '2',
            text: 'Admin siz bilan bog\'lanadi yoki ofisga kelib to\'lovni amalga oshiring',
          ),
          const SizedBox(height: 8),
          _Step(
            number: '3',
            text: 'To\'lov tasdiqlanganidan so\'ng kurs avtomatik ravishda ochiladi',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_rounded, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '+998 71 200 00 00',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
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

class _RedirectHintCard extends StatelessWidget {
  const _RedirectHintCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    height: 1.4,
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

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.selected, required this.onChanged});
  final OrderPaymentMethod selected;
  final ValueChanged<OrderPaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = <(OrderPaymentMethod, String, IconData, Color, bool)>[
      (
        OrderPaymentMethod.cash,
        l.methodCash,
        Icons.payments_rounded,
        AppColors.wine,
        true,
      ),
      (
        OrderPaymentMethod.uzum,
        l.methodUzum,
        Icons.account_balance_wallet_rounded,
        const Color(0xFF7B2CBF),
        false,
      ),
      (
        OrderPaymentMethod.uzumNasiya,
        l.methodUzumNasiya,
        Icons.credit_card_rounded,
        const Color(0xFFFF6B35),
        false,
      ),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final it = items[i];
        final active = it.$1 == selected;
        final isAvailable = it.$5;
        final accent = it.$4;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
            child: Opacity(
              opacity: isAvailable ? 1.0 : 0.5,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isAvailable ? () => onChanged(it.$1) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? accent : Colors.white,
                    border: Border.all(
                      color: active ? accent : AppColors.line,
                      width: 1.4,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Icon(
                        it.$3,
                        color: active ? Colors.white : accent,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          it.$2,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Tez kunda',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
