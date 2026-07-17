import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
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
///
/// Visuals follow Liquid Glass mockup "1d": step progress dots under the
/// title, glass tariff cards with custom radio dots, spring step
/// transitions, and a draw-on success checkmark.
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

  @override
  void initState() {
    super.initState();
    _loadStatusAndTariffs();
  }

  Future<void> _loadStatusAndTariffs() async {
    setState(() {
      _step = _Step.loading;
      _errorMsg = null;
    });
    final repo = ref.read(learningRepositoryProvider);
    try {
      final status = await repo.checkNasiyaStatus();
      if (!mounted) return;

      if (!status.isVerified || !status.hasLimit) {
        // No verification or no credit limit yet — either way the buyer
        // must finish Uzum's own registration/identification first.
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
    if (tariff == null) return;
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
      );
      if (!mounted) return;
      _payment = redirect;

      if (redirect.requiresRegistration) {
        // Uzum says the buyer's registration/identification isn't complete —
        // the redirect is their registration webview, no contract exists yet.
        final done = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => NasiyaWebViewScreen(
              url: redirect.redirectUrl,
              title: "Ro'yxatdan o'tish",
            ),
          ),
        );
        if (!mounted) return;
        if (done == true) {
          _loadStatusAndTariffs();
        } else {
          setState(() {
            _errorMsg =
                "Uzum Nasiya'da identifikatsiyani yakunlab, qayta urinib ko'ring.";
            _step = _Step.tariffs;
          });
        }
        return;
      }

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

  int get _progressIndex => switch (_step) {
        _Step.loading ||
        _Step.registration ||
        _Step.tariffs ||
        _Step.error =>
          0,
        _Step.creating || _Step.confirming => 1,
        _Step.success => 2,
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _GlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            "Nasiya to'lovi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        // Balance the back button so the title stays centered.
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StepDots(activeIndex: _progressIndex),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: GlassMotion.stepSlide,
                  switchInCurve: GlassMotion.stepSlideCurve,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildBody(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_step) {
      case _Step.loading:
      case _Step.creating:
      case _Step.confirming:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.wine),
        );

      case _Step.registration:
        return _RegistrationView(onRegister: _openRegistrationWebview);

      case _Step.tariffs:
        return _TariffPickerView(
          targetTitle: widget.targetTitle,
          amount: widget.amount,
          tariffs: _tariffs,
          selected: _selectedTariff,
          errorMsg: _errorMsg,
          onSelect: (t) => setState(() => _selectedTariff = t),
          onConfirm: _selectedTariff == null ? null : _createContractAndOpenOtp,
        );

      case _Step.success:
        return _SuccessView(
          targetTitle: widget.targetTitle,
          tariff: _selectedTariff,
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

// ───────────────────────── Shared bits ─────────────────────────

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
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
          icon,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

/// Step progress dots — active dot stretches into a pill (mockup 1d).
class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeIndex});
  final int activeIndex;
  static const count = 3;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inactive = dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: GlassMotion.tabMorph,
              curve: GlassMotion.tabMorphCurve,
              width: i == activeIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == activeIndex ? AppColors.wine : inactive,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
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
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Steps ─────────────────────────

class _RegistrationView extends StatelessWidget {
  const _RegistrationView({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassEntrance(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.wine.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.wine.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.badge_outlined,
                  size: 40, color: AppColors.wine),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Uzum Nasiya'da ro'yxatdan o'ting",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Bo'lib to'lash uchun avval Uzum Nasiya tizimida ro'yxatdan "
            "o'tishingiz kerak. Bu bir necha daqiqa vaqt oladi.",
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, height: 1.4),
          ),
          const SizedBox(height: 28),
          _PrimaryCta(label: "Ro'yxatdan o'tish", onTap: onRegister),
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
    required this.onSelect,
    required this.onConfirm,
  });

  final String targetTitle;
  final num amount;
  final List<NasiyaTariff> tariffs;
  final NasiyaTariff? selected;
  final String? errorMsg;
  final ValueChanged<NasiyaTariff> onSelect;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    if (tariffs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            "Hozircha mavjud bo'lib to'lash tariflari yo'q.",
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: [
              GlassEntrance(
                child: Text(
                  'Tarifni tanlang',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$targetTitle · ${amount.toStringAsFixed(0)} so'm",
                style: TextStyle(color: mutedColor, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < tariffs.length; i++)
                GlassEntrance(
                  delay: GlassMotion.entranceStep * (1 + i),
                  child: _TariffTile(
                    tariff: tariffs[i],
                    active: tariffs[i].period == selected?.period,
                    onTap: () => onSelect(tariffs[i]),
                  ),
                ),
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(errorMsg!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
          child: Column(
            children: [
              _PrimaryCta(label: 'Davom etish', onTap: onConfirm),
              const SizedBox(height: 10),
              Text(
                "Nasiya — foizsiz bo'lib to'lash",
                style: TextStyle(fontSize: 11, color: mutedColor),
              ),
            ],
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPressable(
        onTap: onTap,
        child: Stack(
          children: [
            GlassContainer(
              borderRadius: AppColors.radiusTariffCard,
              withShadow: false,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Custom radio dot (mockup 1d)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.wine : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? AppColors.wine
                            : (dark
                                ? AppColors.glassStrokeDark
                                : AppColors.glassStrokeLight),
                        width: 2,
                      ),
                    ),
                    child: active
                        ? const Icon(Icons.circle,
                            size: 8, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tariff.titleUz,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        if (tariff.monthlyPayment != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Oyiga ${tariff.monthlyPayment!.toStringAsFixed(0)} so'm",
                            style: TextStyle(
                                color: mutedColor, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.wine300.withValues(alpha: 0.16)
                          : AppColors.wine100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${tariff.period} oy',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Active border ring on top of the glass surface.
            if (active)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusTariffCard),
                      border: Border.all(color: AppColors.wine, width: 1.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Success ─────────────────────────

class _SuccessView extends StatefulWidget {
  const _SuccessView({
    required this.targetTitle,
    required this.tariff,
    required this.onDone,
  });
  final String targetTitle;
  final NasiyaTariff? tariff;
  final VoidCallback onDone;

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: GlassMotion.successPop,
  );
  late final AnimationController _stroke = AnimationController(
    vsync: this,
    duration: GlassMotion.successStroke,
  );

  @override
  void initState() {
    super.initState();
    _pop.forward();
    Future.delayed(GlassMotion.successStrokeDelay, () {
      if (mounted) _stroke.forward();
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _stroke.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final lineColor = dark ? AppColors.lineDark : AppColors.line;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final tariff = widget.tariff;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 40),
      children: [
        Column(
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                  parent: _pop, curve: Curves.elasticOut),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _stroke,
                  builder: (context, _) => CustomPaint(
                    painter: _CheckPainter(progress: _stroke.value),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "To'lov muvaffaqiyatli!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "To'lovingiz muvaffaqiyatli amalga oshirildi. Kirish ochildi.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 22),
        GlassContainer(
          borderRadius: AppColors.radiusTariffCard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Nomi',
                value: widget.targetTitle,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              Divider(height: 1, thickness: 0.5, color: lineColor),
              if (tariff != null) ...[
                _SummaryRow(
                  label: 'Tarif',
                  value: tariff.titleUz,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                if (tariff.monthlyPayment != null) ...[
                  Divider(height: 1, thickness: 0.5, color: lineColor),
                  _SummaryRow(
                    label: "Oylik to'lov",
                    value:
                        "${tariff.monthlyPayment!.toStringAsFixed(0)} so'm",
                    textColor: accent,
                    mutedColor: mutedColor,
                    emphasize: true,
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _PrimaryCta(label: 'Davom etish', onTap: widget.onDone),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final Color textColor;
  final Color mutedColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: mutedColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draw-on checkmark: reveals the stroke as [progress] goes 0→1 (mockup's
/// stroke-dashoffset animation).
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.53)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.72, h * 0.36);

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ───────────────────────── Error ─────────────────────────

class _ErrorView extends StatefulWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<_ErrorView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: GlassMotion.errorShake,
  )..forward();

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              // Damped horizontal shake, settling at 0.
              final dx =
                  (1 - t) * 8 * (t * 20).remainder(2) * ((t * 20).floor().isEven ? 1 : -1);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _PrimaryCta(label: 'Qayta urinish', onTap: widget.onRetry),
          ),
        ],
      ),
    );
  }
}
