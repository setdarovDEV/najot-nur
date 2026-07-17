import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../features/payments/nasiya_checkout_screen.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';

/// Opens the "buy" / "request access" bottom sheet used by both
/// the course detail screen and the audiobook locked gate.
/// Liquid Glass mockup "1c": frosted sheet over a wine-tinted scrim.
Future<void> showOrderRequestSheet(
  BuildContext context, {
  required OrderPurpose purpose,
  required String targetId,
  required String targetTitle,
  required num amount,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetScrim,
    isScrollControlled: true,
    builder: (_) => GlassSheet(
      child: SingleChildScrollView(
        child: _OrderRequestSheet(
          purpose: purpose,
          targetId: targetId,
          targetTitle: targetTitle,
          amount: amount,
        ),
      ),
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
      if (_method == OrderPaymentMethod.uzumNasiya) {
        // Uzum Nasiya has its own multi-step flow (buyer check → tariff
        // pick → WebView OTP confirm) — hand off to a dedicated screen
        // instead of a single initiate+redirect call.
        Navigator.of(context).pop();
        final purchased = await context.push<bool>(
          '/payments/nasiya',
          extra: NasiyaCheckoutArgs(
            purpose: widget.purpose,
            targetId: widget.targetId,
            targetTitle: widget.targetTitle,
            amount: widget.amount,
          ),
        );
        if (purchased == true) {
          ref.invalidate(myOrdersProvider);
        }
        return;
      }

      if (_method == OrderPaymentMethod.uzum) {
        final redirect = await ref.read(learningRepositoryProvider).initiatePayment(
              provider: 'uzum',
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
            content: Text(l.uzumRedirectHint),
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
    // If Uzum Nasiya trips the circuit breaker while this method is already
    // selected, fall back to cash instead of leaving a blocked option chosen.
    ref.listen(nasiyaAvailabilityProvider, (previous, next) {
      final available = next.valueOrNull?.available ?? true;
      if (!available && _method == OrderPaymentMethod.uzumNasiya) {
        setState(() => _method = OrderPaymentMethod.cash);
      }
    });
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    return Padding(
      padding: EdgeInsets.fromLTRB(6, 6, 6, mq.viewInsets.bottom + 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            widget.purpose == OrderPurpose.course
                ? l.orderSheetCourseTitle
                : l.orderSheetAudiobookTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          // Item summary — icon, title, price (mockup 1c)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.wine.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppColors.wineGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.purpose == OrderPurpose.course
                        ? Icons.play_arrow_rounded
                        : Icons.headphones_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.targetTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.amount.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: dark ? AppColors.wine300 : AppColors.wine,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.paymentMethod.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 8),
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
            const _RedirectHintCard(
              icon: Icons.credit_card_rounded,
              title: 'Uzum Nasiya orqali bo\'lib to\'lash',
              body: 'Davom etsangiz, ro\'yxatdan o\'tish (agar kerak bo\'lsa), '
                  'to\'lov muddatini tanlash va SMS kod bilan tasdiqlash '
                  'bosqichlariga o\'tasiz.',
              color: Color(0xFFFF6B35),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          // Jami row (mockup 1c)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.amountLabel,
                    style: TextStyle(fontSize: 13, color: mutedColor)),
                Text(
                  l.sumPrice(widget.amount.toStringAsFixed(0)),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassPressable(
            onTap: _submitting ? null : _submit,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.wineGradient,
                borderRadius: BorderRadius.circular(AppColors.radiusButton),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.30),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(
                      switch (_method) {
                        OrderPaymentMethod.cash => "So'rov yuborish",
                        OrderPaymentMethod.uzumNasiya => 'Davom etish',
                        OrderPaymentMethod.uzum => l.orderSubmit,
                      },
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
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
              style:
                  TextStyle(color: mutedColor, fontSize: 11, height: 1.4),
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
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
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
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_rounded,
                    color: AppColors.success, size: 17),
              ),
              const SizedBox(width: 10),
              const Text(
                'Naqd to\'lov tartibi',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _Step(
            number: '1',
            text: 'Quyidagi tugmani bosib so\'rov yuboring',
          ),
          const SizedBox(height: 8),
          const _Step(
            number: '2',
            text: 'Admin siz bilan bog\'lanadi yoki ofisga kelib to\'lovni amalga oshiring',
          ),
          const SizedBox(height: 8),
          const _Step(
            number: '3',
            text: 'To\'lov tasdiqlanganidan so\'ng kurs avtomatik ravishda ochiladi',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_rounded, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Text(
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
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.success,
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

class _MethodPicker extends ConsumerWidget {
  const _MethodPicker({required this.selected, required this.onChanged});
  final OrderPaymentMethod selected;
  final ValueChanged<OrderPaymentMethod> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    // Fail open on a loading/error availability check — only the backend's
    // circuit breaker (an explicit `available: false`) should disable this
    // tile, a flaky availability request itself shouldn't.
    final nasiyaAvailability = ref.watch(nasiyaAvailabilityProvider);
    final nasiyaAvailable = nasiyaAvailability.maybeWhen(
      data: (v) => v.available,
      orElse: () => true,
    );
    final items = <(OrderPaymentMethod, String, IconData, bool, String)>[
      (OrderPaymentMethod.cash, l.methodCash, Icons.payments_rounded, true, ''),
      (
        OrderPaymentMethod.uzum,
        l.methodUzum,
        Icons.account_balance_wallet_rounded,
        false,
        'Tez kunda',
      ),
      (
        OrderPaymentMethod.uzumNasiya,
        l.methodUzumNasiya,
        Icons.credit_card_rounded,
        nasiyaAvailable,
        'Texnik ishlar',
      ),
    ];
    final selectedIndex =
        items.indexWhere((it) => it.$1 == selected).clamp(0, items.length - 1);

    // Segmented pill with a morphing indicator (mockup 1c).
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = (constraints.maxWidth - 8) / items.length;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.wine.withValues(alpha: dark ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(AppColors.radiusButton),
          ),
          child: SizedBox(
            height: 58,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: GlassMotion.tabMorph,
                  curve: GlassMotion.tabMorphCurve,
                  left: segmentWidth * selectedIndex,
                  width: segmentWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusSegment),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wineDeep
                              .withValues(alpha: dark ? 0.3 : 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final it in items)
                      Expanded(
                        child: Opacity(
                          opacity: it.$4 ? 1.0 : 0.45,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: it.$4 ? () => onChanged(it.$1) : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  it.$3,
                                  size: 18,
                                  color: it.$1 == selected
                                      ? (dark
                                          ? AppColors.wine300
                                          : AppColors.wine)
                                      : mutedColor,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  it.$4 || it.$5.isEmpty ? it.$2 : it.$5,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: it.$1 == selected
                                        ? textColor
                                        : mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
