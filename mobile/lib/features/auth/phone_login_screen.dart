import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_formatter.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';

enum _Step { phone, password, otp, register }

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  _Step _step = _Step.phone;
  bool _loading = false;
  String? _error;
  bool _telegramBotRequired = false;

  final _phone = TextEditingController(text: '+998 ');
  final _code = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  bool _offerAccepted = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _telegramBotRequired = false;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      final exists =
          await ref.read(authRepositoryProvider).phoneExists(phone);
      if (exists.exists) {
        setState(() => _step = _Step.password);
      } else {
        final devCode =
            await ref.read(authRepositoryProvider).requestOtp(phone);
        if (devCode != null) _code.text = devCode;
        if (mounted) setState(() => _step = _Step.otp);
      }
    } catch (e) {
      if (mounted) {
        final isTgRequired =
            e is ApiException && e.code == 'telegram_bot_required';
        setState(() {
          _error = e.toString();
          _telegramBotRequired = isTgRequired;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      final result = await ref
          .read(authRepositoryProvider)
          .phoneLogin(phone, _password.text.trim());
      await ref
          .read(authControllerProvider.notifier)
          .onAuthenticated(result.access, result.refresh);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      final devCode = await ref.read(authRepositoryProvider).requestOtp(phone);
      if (devCode != null) _code.text = devCode;
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final l = AppLocalizations.of(context);
    if (!_offerAccepted) {
      setState(() => _error = l.offerRequired);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      final result = await ref.read(authRepositoryProvider).verifyOtp(
            phone: phone,
            code: _code.text.trim(),
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            password: _password.text.trim(),
            offerAccepted: true,
          );
      await ref
          .read(authControllerProvider.notifier)
          .onAuthenticated(result.access, result.refresh);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goBack() {
    setState(() {
      _error = null;
      _telegramBotRequired = false;
      if (_step == _Step.password || _step == _Step.otp) {
        _step = _Step.phone;
        _code.clear();
        _password.clear();
      } else if (_step == _Step.register) {
        _step = _Step.otp;
        _firstName.clear();
        _lastName.clear();
        _password.clear();
        _offerAccepted = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.wine,
        elevation: 0,
        leading: _step == _Step.phone
            ? null
            : IconButton(
                onPressed: _loading ? null : _goBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(
          switch (_step) {
            _Step.phone => l.login,
            _Step.password => l.enterPassword,
            _Step.otp => l.verificationCode,
            _Step.register => l.register,
          },
          style: const TextStyle(
            color: AppColors.wine,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(
                  current: _step.index,
                  labels: [l.stepPhone, l.stepVerification, l.stepInfo],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: switch (_step) {
                      _Step.phone => _PhoneStep(
                          phone: _phone,
                          error: _error,
                          loading: _loading,
                          onSubmit: _checkPhone,
                          telegramBotRequired: _telegramBotRequired,
                        ),
                      _Step.password => _PasswordStep(
                          phone: _phone.text.trim(),
                          password: _password,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          error: _error,
                          loading: _loading,
                          onSubmit: _loginWithPassword,
                        ),
                      _Step.otp => _OtpStep(
                          phone: _phone.text.trim(),
                          code: _code,
                          error: _error,
                          loading: _loading,
                          onSubmit: () {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _step = _Step.register);
                            }
                          },
                          onResend: _resendOtp,
                        ),
                      _Step.register => _RegisterStep(
                          firstName: _firstName,
                          lastName: _lastName,
                          password: _password,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          offerAccepted: _offerAccepted,
                          onOfferChanged: (v) =>
                              setState(() => _offerAccepted = v ?? false),
                          error: _error,
                          loading: _loading,
                          onSubmit: _register,
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.labels});
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

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
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
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.ink,
          ),
          inputFormatters: [
            UzPhoneInputFormatter(),
          ],
          validator: (v) {
            final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length < 12) {
              return l.invalidPhone;
            }
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
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
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
        if (telegramBotRequired) ...[
          const SizedBox(height: 10),
          const _TelegramBotBanner(),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const _Spinner()
              : Text(l.continueAction),
        ),
      ],
    );
  }
}

class _TelegramBotBanner extends StatelessWidget {
  const _TelegramBotBanner();

  static const _botUrl = 'https://t.me/najotnurnotiqai_bot';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(_botUrl),
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
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@najotnurnotiqai_bot',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0277BD),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Botga kiring va /start bosing',
                    style: TextStyle(fontSize: 12, color: Color(0xFF455A64)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF29B6F6)),
          ],
        ),
      ),
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.phone,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });
  final String phone;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l.enterPasswordFor(phone),
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: password,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          validator: (v) {
            if (v == null || v.trim().length < 6) {
              return l.passwordTooShort;
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: l.password,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.wine),
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.muted,
              ),
            ),
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
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const _Spinner()
              : Text(l.login),
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
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
        const SizedBox(height: 24),
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
              ? const _Spinner()
              : Text(l.continueAction),
        ),
      ],
    );
  }
}

class _RegisterStep extends StatelessWidget {
  const _RegisterStep({
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
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
              ? const _Spinner()
              : Text(l.registerAndLogin),
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
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
