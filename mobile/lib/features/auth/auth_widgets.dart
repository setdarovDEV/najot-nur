import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_formatter.dart';
import '../../l10n/gen/app_localizations.dart';

/// 6 ta alohida katakchali OTP kiritish widget'i.
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
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, _buildBox),
    );
  }

  Widget _buildBox(int i) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.wine,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.wine, width: 2),
          ),
          filled: true,
          fillColor: AppColors.wine100,
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
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.wine : AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.wine : AppColors.muted,
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
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.ink,
      ),
      inputFormatters: [UzPhoneInputFormatter()],
      validator: validator ??
          (v) {
            final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length < 12) return l.invalidPhone;
            return null;
          },
      decoration: InputDecoration(
        labelText: l.phoneNumber,
        hintText: l.phoneHint,
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 6),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.wine100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.phone_iphone_rounded,
            color: AppColors.wine,
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.wine, width: 1.6),
        ),
      ),
    );
  }
}

/// Step 2: enter the Telegram verification code we just sent. The
/// banner tells the user where to find it inside Telegram.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l.verificationCode,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l.enterCodeFor(phone),
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const TelegramVerificationHint(),
        const SizedBox(height: 20),
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
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: loading ? null : onResend,
            child: Text(
              l.resendCode,
              style: const TextStyle(color: AppColors.wine),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const Spinner()
              : Text(l.continueAction),
        ),
      ],
    );
  }
}

/// Small inline hint pointing the user at Telegram's official
/// "Verification Codes" chat. Codes are sent there automatically — no
/// custom bot or `/start` flow needed. Tapping the hint opens the
/// Telegram search with that chat pre-filtered.
class TelegramVerificationHint extends StatelessWidget {
  const TelegramVerificationHint({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        // Telegram deep-link that opens the official "Verification Codes"
        // chat. Works in both the standalone Telegram app and the in-app
        // browser on iOS / Android.
        Uri.parse('tg://resolve?domain=verify'),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF29B6F6), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF29B6F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telegram → "Verification Codes"',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0277BD),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '6 xonali kod shu chatga yuborildi',
                    style: TextStyle(fontSize: 12, color: Color(0xFF455A64)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF29B6F6),
            ),
          ],
        ),
      ),
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
