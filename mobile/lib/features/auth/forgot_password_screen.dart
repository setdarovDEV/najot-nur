import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_formatter.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import 'auth_widgets.dart';

enum _ForgotStep { phone, code, password }

/// Standalone forgot-password flow:
///   1. Enter phone number
///   2. Type the 6-digit Telegram verification code
///   3. Set a new password and sign in automatically.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.phone;
  bool _loading = false;
  String? _error;

  final _phone = TextEditingController(text: '+998 ');
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      final exists = await ref.read(authRepositoryProvider).phoneExists(phone);
      if (!mounted) return;
      if (!exists.exists) {
        setState(() => _error = l.phoneNotRegistered);
        return;
      }
      await ref.read(authRepositoryProvider).requestOtp(phone);
      if (!mounted) return;
      setState(() => _step = _ForgotStep.code);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      await ref.read(authRepositoryProvider).checkOtp(
            phone: phone,
            code: _code.text.trim(),
          );
      if (!mounted) return;
      setState(() => _step = _ForgotStep.password);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      await ref.read(authRepositoryProvider).requestOtp(phone);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      final result = await ref.read(authRepositoryProvider).resetPassword(
            phone: phone,
            code: _code.text.trim(),
            newPassword: _password.text.trim(),
          );
      if (!mounted) return;
      await ref
          .read(authControllerProvider.notifier)
          .onAuthenticated(result.access, result.refresh);
      if (!mounted) return;
      final pending = ref.read(pendingReturnPathProvider);
      if (pending != null) {
        ref.read(pendingReturnPathProvider.notifier).state = null;
        context.go(pending);
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goBack() {
    setState(() {
      _error = null;
      if (_step == _ForgotStep.code) {
        _step = _ForgotStep.phone;
        _code.clear();
      } else if (_step == _ForgotStep.password) {
        _step = _ForgotStep.code;
        _password.clear();
        _confirmPassword.clear();
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
        leading: IconButton(
          onPressed: _loading ? null : _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          l.forgotPassword,
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
                StepIndicator(
                  current: _step.index,
                  labels: [l.stepPhone, l.stepVerification, l.stepNewPassword],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: switch (_step) {
                      _ForgotStep.phone => _PhoneStep(
                          phone: _phone,
                          loading: _loading,
                          error: _error,
                          onSubmit: _sendCode,
                        ),
                      _ForgotStep.code => CodeStep(
                          phone: _phone.text.trim(),
                          code: _code,
                          error: _error,
                          loading: _loading,
                          onSubmit: _verifyCode,
                          onResend: _resendCode,
                        ),
                      _ForgotStep.password => _NewPasswordStep(
                          password: _password,
                          confirmPassword: _confirmPassword,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          loading: _loading,
                          error: _error,
                          onSubmit: _resetPassword,
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

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    required this.phone,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController phone;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

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
          l.enterPhoneForReset,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        PhoneField(controller: phone),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading ? const Spinner() : Text(l.sendCode),
        ),
      ],
    );
  }
}

class _NewPasswordStep extends StatelessWidget {
  const _NewPasswordStep({
    required this.password,
    required this.confirmPassword,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l.createNewPassword,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.wine,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.createNewPasswordSubtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: password,
          obscureText: obscure,
          validator: (v) {
            if (v == null || v.trim().length < 6) return l.passwordTooShort;
            return null;
          },
          decoration: InputDecoration(
            labelText: l.newPassword,
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
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: confirmPassword,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l.confirmPasswordRequired;
            if (v.trim() != password.text.trim()) return l.passwordsDoNotMatch;
            return null;
          },
          decoration: InputDecoration(
            labelText: l.confirmPassword,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.wine),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading ? const Spinner() : Text(l.saveAndLogin),
        ),
      ],
    );
  }
}
