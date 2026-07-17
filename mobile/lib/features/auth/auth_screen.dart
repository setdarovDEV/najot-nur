import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (_step != _Step.phone)
                          _GlassBackButton(
                            onTap: _loading ? null : _goBack,
                          )
                        else
                          const SizedBox(width: 40, height: 40),
                        Expanded(
                          child: Text(
                            l.registerLogin,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 14),
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
        ],
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

/// Circular frosted back button used above the step content.
class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
  final VoidCallback? onTap;

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
          Icons.arrow_back_rounded,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

/// Login / Register segmented control on a glass track (mockup segments).
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.glassFillDark : AppColors.glassFillLight,
        borderRadius: BorderRadius.circular(AppColors.radiusSegment),
        border: Border.all(
          color: dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight,
          width: 0.5,
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppColors.wineGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.wine.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: mutedColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        splashBorderRadius: BorderRadius.circular(12),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        GlassEntrance(
          child: Column(
            children: [
              const AuthBrandMark(),
              const SizedBox(height: 16),
              Text(
                l.welcome,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                mode == _AuthMode.login
                    ? l.enterPhoneForLogin
                    : l.enterPhoneForRegister,
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        GlassEntrance(
          delay: GlassMotion.entranceStep,
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhoneField(controller: phone),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 14),
                GlassCta(
                  label: l.continueAction,
                  loading: loading,
                  onTap: onSubmit,
                ),
                const SizedBox(height: 12),
                Text(
                  l.termsNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.5,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
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
                l.enterPasswordFor(phone),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.loginSubtitle,
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
                TextFormField(
                  controller: password,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                  style: TextStyle(color: textColor),
                  validator: (v) {
                    if (v == null || v.trim().length < 6) {
                      return l.passwordTooShort;
                    }
                    return null;
                  },
                  decoration: glassFieldDecoration(
                    context,
                    label: l.password,
                    prefixIcon: Icon(Icons.lock_outline, color: accent),
                    suffixIcon: IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : onForgot,
                    child: Text(
                      l.forgotPassword,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GlassCta(label: l.login, loading: loading, onTap: onSubmit),
              ],
            ),
          ),
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
        Builder(builder: (context) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dark
                  ? AppColors.wine300.withValues(alpha: 0.12)
                  : AppColors.wine100,
              borderRadius: BorderRadius.circular(AppColors.radiusSegment),
              border: Border.all(
                color: dark ? AppColors.lineDark : AppColors.line,
                width: 0.5,
              ),
            ),
            child: CheckboxListTile(
              value: offerAccepted,
              onChanged: onOfferChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.wine,
              title: Text(
                l.offerAcceptTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.offerAcceptSubtitle,
                  style: TextStyle(
                    color: dark ? AppColors.mutedDark : AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
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
