import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_formatter.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import 'auth_widgets.dart';

/// Login: phone + password.
/// Redirects to the register flow when the phone isn't on file.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  final _phone = TextEditingController(text: '+998 ');
  final _password = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.wine,
        elevation: 0,
        title: Text(
          l.login,
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          l.welcomeBack,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.wine,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.loginSubtitle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PhoneField(controller: _phone),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.trim().length < 6) {
                              return l.passwordTooShort;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: l.password,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.wine,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.muted,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.wine, width: 1.6),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const Spinner()
                              : Text(l.login),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading ? null : () => context.go('/auth/register'),
                          child: Text(
                            l.noAccountRegister,
                            style: const TextStyle(color: AppColors.wine),
                          ),
                        ),
                      ],
                    ),
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
