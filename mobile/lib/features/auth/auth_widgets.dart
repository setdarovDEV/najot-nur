import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../core/utils/phone_formatter.dart';
import '../../l10n/gen/app_localizations.dart';

/// Circular brand mark used across the auth screens (Liquid Glass mockup
/// "3b"): gradient wine circle with the white logo and a deep drop shadow.
class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.wineDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.wineDeep.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.22),
        child:
            Image.asset('assets/images/logo_white.png', fit: BoxFit.contain),
      ),
    );
  }
}

/// Primary gradient CTA (54px, mockup 3b) with the built-in loading spinner.
class GlassCta extends StatelessWidget {
  const GlassCta({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || loading;
    return GlassPressable(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled && !loading ? 0.5 : 1,
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
          child: loading
              ? const Spinner()
              : Text(
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

/// Shared glass text-field decoration: radius 16, 1.5px hairline stroke,
/// translucent wine-tinted fill (mockup 3b).
InputDecoration glassFieldDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
  final fill = dark
      ? Colors.white.withValues(alpha: 0.06)
      : AppColors.wine.withValues(alpha: 0.05);
  final stroke =
      dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight;
  final accent = dark ? AppColors.wine300 : AppColors.wine;

  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(color: mutedColor, fontSize: 14),
    hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.7)),
    filled: true,
    fillColor: fill,
    border: border(stroke),
    enabledBorder: border(stroke),
    focusedBorder: border(accent),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
  );
}

/// 6 ta alohida katakchali OTP kiritish widget'i — 62px glass boxes,
/// radius 16 (mockup 1d/3b style).
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.onCompleted,
  });

  final TextEditingController controller;
  final VoidCallback? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(6, (_) => TextEditingController());
    _nodes = List.generate(6, (_) => FocusNode());
    for (int i = 0; i < 6; i++) {
      final idx = i;
      _nodes[idx].onKeyEvent = (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _ctrls[idx].text.isEmpty &&
            idx > 0) {
          _ctrls[idx - 1].clear();
          _nodes[idx - 1].requestFocus();
          _syncParent();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _syncParent() {
    widget.controller.text = _ctrls.map((c) => c.text).join();
  }

  void _onChanged(String val, int idx) {
    if (val.length > 1) {
      // paste holatini boshqarish
      final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < 6; i++) {
        _ctrls[i].text = i < digits.length ? digits[i] : '';
      }
      _syncParent();
      final next = digits.length < 6 ? digits.length : 5;
      _nodes[next].requestFocus();
      if (digits.length >= 6) widget.onCompleted?.call();
      return;
    }
    _syncParent();
    if (val.isNotEmpty && idx < 5) {
      _nodes[idx + 1].requestFocus();
    }
    if (widget.controller.text.length == 6) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 6; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 5 ? 0 : 8),
              child: _buildBox(i),
            ),
          ),
      ],
    );
  }

  Widget _buildBox(int i) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final fill = dark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.wine.withValues(alpha: 0.05);
    final stroke =
        dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 1.5),
        );

    return SizedBox(
      height: 62,
      child: TextFormField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: border(stroke),
          enabledBorder: border(stroke),
          focusedBorder: border(accent),
          filled: true,
          fillColor: fill,
        ),
        onChanged: (val) => _onChanged(val, i),
      ),
    );
  }
}

/// Slim top progress bar that highlights the current step. Shared by
/// the multi-step registration flow.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.current,
    required this.labels,
  });

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final inactive = dark ? AppColors.lineDark : AppColors.line;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: GlassMotion.tabMorph,
                  curve: Curves.easeOut,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? accent : inactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? accent : mutedColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Reusable phone field with the Uzbekistan formatter. Label / hint /
/// validator messages all come from the AppLocalizations.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: textColor,
      ),
      inputFormatters: [UzPhoneInputFormatter()],
      validator: validator ??
          (v) {
            final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length < 12) return l.invalidPhone;
            return null;
          },
      decoration: glassFieldDecoration(
        context,
        label: l.phoneNumber,
        hint: l.phoneHint,
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 6),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark
                ? AppColors.wine300.withValues(alpha: 0.16)
                : AppColors.wine100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.phone_iphone_rounded,
            color: accent,
            size: 20,
          ),
        ),
      ).copyWith(
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

/// Step 2: enter the 6-digit SMS verification code.
class CodeStep extends StatelessWidget {
  const CodeStep({
    super.key,
    required this.phone,
    required this.code,
    required this.error,
    required this.loading,
    required this.onSubmit,
    required this.onResend,
  });

  final String phone;
  final TextEditingController code;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        GlassEntrance(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.verificationCode,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.enterCodeFor(phone),
                style: TextStyle(color: mutedColor, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassEntrance(
          delay: GlassMotion.entranceStep,
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormField<String>(
                  validator: (_) {
                    if (code.text.length < 6) return l.codeTooShort;
                    return null;
                  },
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OtpInput(
                        controller: code,
                        onCompleted: onSubmit,
                      ),
                      if (field.errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          field.errorText!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: loading ? null : onResend,
                    child: Text(
                      l.resendCode,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GlassCta(
                  label: l.continueAction,
                  loading: loading,
                  onTap: onSubmit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// White circular spinner sized for use inside buttons.
class Spinner extends StatelessWidget {
  const Spinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2.4,
      ),
    );
  }
}
