import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_formatter.dart';
import '../../data/repositories.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import 'auth_widgets.dart';

enum _AuthMode { login, register }

enum _Step { phone, code, password, info }

/// Single auth entry point. Two top tabs — Login and Register — share the
/// same phone-first flow:
///
///   Login:    phone → password
///   Register: phone → 6-digit SMS code → name + password
///
/// Successful auth stashes the JWT pair and redirects to the pending return
/// path (if any) or `/home`.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  _AuthMode _mode = _AuthMode.login;
  _Step _step = _Step.phone;
  bool _loading = false;
  String? _error;

  final _phone = TextEditingController(text: '+998 ');
  final _code = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _offerAccepted = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 0 && _mode != _AuthMode.login) {
      _switchMode(_AuthMode.login);
    } else if (_tabController.index == 1 && _mode != _AuthMode.register) {
      _switchMode(_AuthMode.register);
    }
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _step = _Step.phone;
      _error = null;
      _code.clear();
      _firstName.clear();
      _lastName.clear();
      _password.clear();
      _confirmPassword.clear();
      _offerAccepted = false;
    });
    _tabController.index = mode == _AuthMode.login ? 0 : 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phone.dispose();
    _code.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onPhoneSubmitted() async {
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
      if (_mode == _AuthMode.register) {
        if (exists.exists) {
          setState(() => _error = l.phoneAlreadyRegistered);
          return;
        }
        await ref.read(authRepositoryProvider).requestOtp(phone);
        if (!mounted) return;
        setState(() => _step = _Step.code);
      } else {
        if (!exists.exists) {
          // No account for this number — skip the confusing password
          // prompt entirely and drop the user straight into the register
          // flow's OTP step, with the code already on its way.
          await ref.read(authRepositoryProvider).requestOtp(phone);
          if (!mounted) return;
          setState(() {
            _mode = _AuthMode.register;
            _step = _Step.code;
          });
          _tabController.index = 1;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.phoneNotRegistered)),
          );
          return;
        }
        setState(() => _step = _Step.password);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onCodeSubmitted() async {
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
      setState(() => _step = _Step.info);
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

  Future<void> _onPasswordSubmitted() async {
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
      if (!mounted) return;
      await _finishAuth(result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRegisterCompleted() async {
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
      if (!mounted) return;
      await _finishAuth(result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishAuth(AuthResult result) async {
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
  }

  void _goBack() {
    setState(() {
      _error = null;
      if (_step == _Step.code) {
        _step = _Step.phone;
        _code.clear();
      } else if (_step == _Step.info) {
        _step = _Step.code;
        _firstName.clear();
        _lastName.clear();
        _password.clear();
        _confirmPassword.clear();
        _offerAccepted = false;
      } else if (_step == _Step.password) {
        _step = _Step.phone;
        _password.clear();
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
        automaticallyImplyLeading: false,
        leading: _step != _Step.phone
            ? IconButton(
                onPressed: _loading ? null : _goBack,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(
          l.registerLogin,
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
                _ModeTabs(
                  controller: _tabController,
                  loginLabel: l.login,
                  registerLabel: l.register,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStep(l),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l) {
    switch (_step) {
      case _Step.phone:
        return _PhoneStep(
          phone: _phone,
          mode: _mode,
          loading: _loading,
          error: _error,
          onSubmit: _onPhoneSubmitted,
        );
      case _Step.password:
        return _PasswordStep(
          phone: _phone.text.trim(),
          password: _password,
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          loading: _loading,
          error: _error,
          onSubmit: _onPasswordSubmitted,
          onForgot: () => context.push('/auth/forgot-password'),
        );
      case _Step.code:
        return CodeStep(
          phone: _phone.text.trim(),
          code: _code,
          error: _error,
          loading: _loading,
          onSubmit: _onCodeSubmitted,
          onResend: _resendCode,
        );
      case _Step.info:
        return _RegisterInfoStep(
          firstName: _firstName,
          lastName: _lastName,
          password: _password,
          confirmPassword: _confirmPassword,
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          offerAccepted: _offerAccepted,
          onOfferChanged: (v) => setState(() => _offerAccepted = v ?? false),
          loading: _loading,
          error: _error,
          onSubmit: _onRegisterCompleted,
        );
    }
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.controller,
    required this.loginLabel,
    required this.registerLabel,
  });

  final TabController controller;
  final String loginLabel;
  final String registerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.wine100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.wine,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.wine,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: [
          Tab(text: loginLabel),
          Tab(text: registerLabel),
        ],
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    required this.phone,
    required this.mode,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController phone;
  final _AuthMode mode;
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
          mode == _AuthMode.login
              ? l.enterPhoneForLogin
              : l.enterPhoneForRegister,
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
          child: loading ? const Spinner() : Text(l.continueAction),
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.phone,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.error,
    required this.onSubmit,
    required this.onForgot,
  });

  final String phone;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l.enterPasswordFor(phone),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l.loginSubtitle,
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
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgot,
            child: Text(
              l.forgotPassword,
              style: const TextStyle(color: AppColors.wine),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading ? const Spinner() : Text(l.login),
        ),
      ],
    );
  }
}

class _RegisterInfoStep extends StatelessWidget {
  const _RegisterInfoStep({
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.confirmPassword,
    required this.obscure,
    required this.onToggleObscure,
    required this.offerAccepted,
    required this.onOfferChanged,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool offerAccepted;
  final ValueChanged<bool?> onOfferChanged;
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
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: password,
          obscureText: obscure,
          validator: (v) {
            if (v == null || v.trim().length < 6) return l.passwordTooShort;
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
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: confirmPassword,
          obscureText: obscure,
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
            activeColor: AppColors.wine,
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
          child: loading ? const Spinner() : Text(l.registerAndLogin),
        ),
      ],
    );
  }
}
