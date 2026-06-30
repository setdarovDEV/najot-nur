import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_formatter.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import 'auth_widgets.dart';

enum _Step { phone, code, info }

/// 3-step registration flow:
///   1. Phone number
///   2. Telegram verification code (verified server-side before continuing)
///   3. First name, last name, password
///
/// Each step is gated: the user cannot advance until the previous step's
/// server call succeeds. The code from step 2 is intentionally *not*
/// consumed by `/auth/otp/check` — it's re-sent with the name + password
/// in step 3 to `/auth/otp/verify` (which is the call that actually
/// creates the user and issues the JWT pair).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _telegramBotRequired = false;
    });
    try {
      final phone = normaliseUzPhone(_phone.text);
      final devCode =
          await ref.read(authRepositoryProvider).requestOtp(phone);
      if (devCode != null) _code.text = devCode;
      if (mounted) setState(() => _step = _Step.code);
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
      if (mounted) setState(() => _step = _Step.info);
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
      final devCode = await ref.read(authRepositoryProvider).requestOtp(phone);
      if (devCode != null) _code.text = devCode;
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
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
      _telegramBotRequired = false;
      if (_step == _Step.code) {
        _step = _Step.phone;
        _code.clear();
      } else if (_step == _Step.info) {
        _step = _Step.code;
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
          l.register,
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
                  labels: [l.stepPhone, l.stepVerification, l.stepInfo],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: switch (_step) {
                      _Step.phone => PhoneStep(
                          phone: _phone,
                          error: _error,
                          loading: _loading,
                          telegramBotRequired: _telegramBotRequired,
                          onSubmit: _sendCode,
                        ),
                      _Step.code => CodeStep(
                          phone: _phone.text.trim(),
                          code: _code,
                          error: _error,
                          loading: _loading,
                          onSubmit: _verifyCode,
                          onResend: _resendCode,
                        ),
                      _Step.info => InfoStep(
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
                          onSubmit: _complete,
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
