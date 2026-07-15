import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import 'nasiya_webview_screen.dart';

enum _Step { loading, registration, tariffs, creating, confirming, success, error }

/// Navigation payload for the `/payments/nasiya` route (passed via
/// `GoRouterState.extra`).
class NasiyaCheckoutArgs {
  const NasiyaCheckoutArgs({
    required this.purpose,
    required this.targetId,
    required this.targetTitle,
    required this.amount,
  });

  final OrderPurpose purpose;
  final String targetId;
  final String targetTitle;
  final num amount;
}

/// Full Uzum Nasiya (installment) purchase flow for a course/audiobook:
///  1. check-status — is the buyer already verified with Uzum Nasiya?
///     no  → open the registration WebView, then re-check
///     yes → go to 2
///  2. calculate — show available tariffs (period + monthly payment) for
///     [amount], buyer picks one
///  3. initiate — creates the contract, opens the OTP WebView
///     (sandbox: static code 111111)
///  4. confirm — once the WebView reaches our return-URL sentinel, activate
///     the contract; on success the course/audiobook unlocks immediately.
class NasiyaCheckoutScreen extends ConsumerStatefulWidget {
  const NasiyaCheckoutScreen({
    super.key,
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
  ConsumerState<NasiyaCheckoutScreen> createState() =>
      _NasiyaCheckoutScreenState();
}

class _NasiyaCheckoutScreenState extends ConsumerState<NasiyaCheckoutScreen> {
  _Step _step = _Step.loading;
  String? _errorMsg;
  NasiyaStatus? _status;
  List<NasiyaTariff> _tariffs = [];
  NasiyaTariff? _selectedTariff;
  PaymentRedirect? _payment;
  final _pinflController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final knownPinfl =
        ref.read(authControllerProvider.select((s) => s.user?.pinfl));
    if (knownPinfl != null && knownPinfl.isNotEmpty) {
      _pinflController.text = knownPinfl;
    }
    _loadStatusAndTariffs();
  }

  @override
  void dispose() {
    _pinflController.dispose();
    super.dispose();
  }

  bool get _pinflValid =>
      RegExp(r'^\d{14}$').hasMatch(_pinflController.text.trim());

  Future<void> _loadStatusAndTariffs() async {
    setState(() {
      _step = _Step.loading;
      _errorMsg = null;
    });
    final repo = ref.read(learningRepositoryProvider);
    try {
      final status = await repo.checkNasiyaStatus();
      if (!mounted) return;

      if (!status.isVerified) {
        setState(() {
          _status = status;
          _step = _Step.registration;
        });
        return;
      }

      List<NasiyaTariff> tariffs = status.availablePeriods;
      try {
        final calculated = await repo.calculateNasiya(
          amount: widget.amount,
          referenceId: widget.targetId,
        );
        if (calculated.isNotEmpty) tariffs = calculated;
      } catch (_) {
        // Fall back to the plain periods from check-status if calculate fails.
      }

      if (!mounted) return;
      setState(() {
        _status = status;
        _tariffs = tariffs;
        _step = _Step.tariffs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _step = _Step.error;
      });
    }
  }

  Future<void> _openRegistrationWebview() async {
    final webview = _status?.webview ?? '';
    if (webview.isEmpty) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NasiyaWebViewScreen(
          url: webview,
          title: "Ro'yxatdan o'tish",
        ),
      ),
    );
    if (!mounted || done != true) return;
    _loadStatusAndTariffs();
  }

  Future<void> _createContractAndOpenOtp() async {
    final tariff = _selectedTariff;
    if (tariff == null || !_pinflValid) return;
    setState(() {
      _step = _Step.creating;
      _errorMsg = null;
    });
    final repo = ref.read(learningRepositoryProvider);
    try {
      final redirect = await repo.initiatePayment(
        provider: 'uzum_nasiya',
        purpose: widget.purpose.apiValue,
        amount: widget.amount,
        courseId: widget.purpose == OrderPurpose.course ? widget.targetId : null,
        audiobookId:
            widget.purpose == OrderPurpose.audiobook ? widget.targetId : null,
        returnUrl: AppConstants.nasiyaReturnUrl,
        period: tariff.period,
        productName: widget.targetTitle,
        pinfl: _pinflController.text.trim(),
      );
      if (!mounted) return;
      _payment = redirect;

      final otpDone = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => NasiyaWebViewScreen(
            url: redirect.redirectUrl,
            title: 'SMS kodni tasdiqlash',
            returnUrlPrefix: AppConstants.nasiyaReturnUrl,
          ),
        ),
      );
      if (!mounted) return;

      if (otpDone == true) {
        await _confirmPayment();
      } else {
        setState(() => _step = _Step.tariffs);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _step = _Step.tariffs;
      });
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _step = _Step.confirming);
    final repo = ref.read(learningRepositoryProvider);
    try {
      await repo.confirmNasiya(_payment!.paymentId);
      if (!mounted) return;
      if (widget.purpose == OrderPurpose.course) {
        ref.invalidate(courseProgressProvider(widget.targetId));
      } else {
        ref.invalidate(audiobookAccessProvider(widget.targetId));
      }
      setState(() => _step = _Step.success);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _step = _Step.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text('Uzum Nasiya',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_step) {
      case _Step.loading:
      case _Step.creating:
      case _Step.confirming:
        return const Center(child: CircularProgressIndicator());

      case _Step.registration:
        return _RegistrationView(onRegister: _openRegistrationWebview);

      case _Step.tariffs:
        return _TariffPickerView(
          targetTitle: widget.targetTitle,
          amount: widget.amount,
          tariffs: _tariffs,
          selected: _selectedTariff,
          errorMsg: _errorMsg,
          pinflController: _pinflController,
          pinflValid: _pinflValid,
          onSelect: (t) => setState(() => _selectedTariff = t),
          onPinflChanged: (_) => setState(() {}),
          onConfirm: (_selectedTariff == null || !_pinflValid)
              ? null
              : _createContractAndOpenOtp,
        );

      case _Step.success:
        return _SuccessView(
          onDone: () => context.pop(true),
        );

      case _Step.error:
        return _ErrorView(
          message: _errorMsg ?? "Noma'lum xatolik yuz berdi.",
          onRetry: _loadStatusAndTariffs,
        );
    }
  }
}

class _RegistrationView extends StatelessWidget {
  const _RegistrationView({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge_outlined, size: 64, color: AppColors.wine),
          const SizedBox(height: 20),
          const Text(
            "Uzum Nasiya'da ro'yxatdan o'ting",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            "Bo'lib to'lash uchun avval Uzum Nasiya tizimida ro'yxatdan "
            "o'tishingiz kerak. Bu bir necha daqiqa vaqt oladi.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Ro'yxatdan o'tish",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffPickerView extends StatelessWidget {
  const _TariffPickerView({
    required this.targetTitle,
    required this.amount,
    required this.tariffs,
    required this.selected,
    required this.errorMsg,
    required this.pinflController,
    required this.pinflValid,
    required this.onSelect,
    required this.onPinflChanged,
    required this.onConfirm,
  });

  final String targetTitle;
  final num amount;
  final List<NasiyaTariff> tariffs;
  final NasiyaTariff? selected;
  final String? errorMsg;
  final TextEditingController pinflController;
  final bool pinflValid;
  final ValueChanged<NasiyaTariff> onSelect;
  final ValueChanged<String> onPinflChanged;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    if (tariffs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "Hozircha mavjud bo'lib to'lash tariflari yo'q.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(targetTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${amount.toStringAsFixed(0)} so\'m',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              const Text("To'lov muddatini tanlang",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted)),
              const SizedBox(height: 10),
              ...tariffs.map((t) => _TariffTile(
                    tariff: t,
                    active: t.period == selected?.period,
                    onTap: () => onSelect(t),
                  )),
              const SizedBox(height: 18),
              const Text("JSHSHIR (PINFL) raqamingiz",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: pinflController,
                onChanged: onPinflChanged,
                keyboardType: TextInputType.number,
                maxLength: 14,
                decoration: InputDecoration(
                  hintText: '14 ta raqam',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(errorMsg!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppColors.line,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Davom etish',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TariffTile extends StatelessWidget {
  const _TariffTile({
    required this.tariff,
    required this.active,
    required this.onTap,
  });

  final NasiyaTariff tariff;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF6B35).withValues(alpha: 0.08) : Colors.white,
            border: Border.all(
              color: active ? const Color(0xFFFF6B35) : AppColors.line,
              width: active ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.radio_button_checked : Icons.radio_button_off,
                color: active ? const Color(0xFFFF6B35) : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tariff.titleUz,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (tariff.monthlyPayment != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        "Oyiga ${tariff.monthlyPayment!.toStringAsFixed(0)} so'm",
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: Color(0xFF16A34A)),
          const SizedBox(height: 20),
          const Text(
            "Shartnoma faollashtirildi!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            "To'lovingiz muvaffaqiyatli amalga oshirildi. Kursga kirish ochildi.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Davom etish',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onRetry, child: const Text('Qayta urinish')),
        ],
      ),
    );
  }
}
