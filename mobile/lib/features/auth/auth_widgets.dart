import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_formatter.dart';
import '../../l10n/gen/app_localizations.dart';

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

/// Step 1 of registration: phone entry.
class PhoneStep extends StatelessWidget {
  const PhoneStep({
    super.key,
    required this.phone,
    required this.error,
    required this.loading,
    required this.onSubmit,
    this.telegramBotRequired = false,
  });

  final TextEditingController phone;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;
  final bool telegramBotRequired;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l.enterPhoneTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l.enterPhoneSubtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        PhoneField(controller: phone),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        if (telegramBotRequired) ...[
          const SizedBox(height: 10),
          const TelegramVerificationHint(),
        ],
        const SizedBox(height: 28),
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
        const SizedBox(height: 16),
        TextFormField(
          controller: code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 12,
            color: AppColors.wine,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (v) {
            if (v == null || v.trim().length < 4) {
              return l.codeTooShort;
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: l.passwordHint,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.wine, width: 1.6),
            ),
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

/// Step 3: name + password + offer agreement.
class InfoStep extends StatelessWidget {
  const InfoStep({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.offerAccepted,
    required this.onOfferChanged,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool offerAccepted;
  final ValueChanged<bool?> onOfferChanged;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const wine = AppColors.wine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l.fillInfoTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.wine,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.fillInfoSubtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: firstName,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.enterFirstName : null,
          decoration: InputDecoration(
            labelText: l.firstName,
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.wine),
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.wine, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: lastName,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.enterLastName : null,
          decoration: InputDecoration(
            labelText: l.lastName,
            prefixIcon: const Icon(Icons.person, color: AppColors.wine),
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.wine, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: password,
          obscureText: obscure,
          validator: (v) {
            if (v == null || v.trim().length < 6) {
              return l.passwordTooShort;
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: l.createPassword,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.wine),
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.muted,
              ),
            ),
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.wine, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.wine100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: CheckboxListTile(
            value: offerAccepted,
            onChanged: onOfferChanged,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: wine,
            title: Text(
              l.offerAcceptTitle,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.offerAcceptSubtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const Spinner()
              : Text(l.registerAndLogin),
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
