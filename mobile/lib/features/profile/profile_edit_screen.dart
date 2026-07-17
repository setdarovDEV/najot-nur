import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../auth/auth_widgets.dart' show glassFieldDecoration;

/// Profile edit, Liquid Glass style: glass back header, auth-style glass
/// inputs on a frosted card and a gradient save CTA.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _scrollOffset = ValueNotifier<double>(0);
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _email = TextEditingController();
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(authRepositoryProvider).updateMe(
            fullName: _name.text.trim(),
            email: _email.text.trim(),
          );
      ref.read(authControllerProvider.notifier).updateUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.profileUpdated)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.errorPrefix(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    if (!ref.watch(authControllerProvider).isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          user == null
              ? ErrorView(message: l.loginRequiredMessage)
              : Form(
                  key: _form,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.axis == Axis.vertical) {
                        _scrollOffset.value = n.metrics.pixels;
                      }
                      return false;
                    },
                    child: ListView(
                      padding:
                          EdgeInsets.fromLTRB(16, topInset + 12, 16, 60),
                      children: [
                        GlassEntrance(
                          child: Row(
                            children: [
                              _GlassBackButton(onTap: () => context.pop()),
                              Expanded(
                                child: Text(
                                  l.profileEdit,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        GlassEntrance(
                          delay: GlassMotion.entranceStep,
                          child: GlassContainer(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _name,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  style: TextStyle(
                                      fontSize: 14.5, color: textColor),
                                  decoration: glassFieldDecoration(
                                    context,
                                    label: l.fullName,
                                    prefixIcon: const Icon(
                                        Icons.person_outline_rounded),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return l.fullNameRequired;
                                    }
                                    if (v.trim().length < 2) {
                                      return l.fullNameTooShort;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _email,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  autocorrect: false,
                                  autofillHints: const [],
                                  style: TextStyle(
                                      fontSize: 14.5, color: textColor),
                                  decoration: glassFieldDecoration(
                                    context,
                                    label: l.emailOptional,
                                    hint: 'name@example.com',
                                    prefixIcon: const Icon(
                                        Icons.alternate_email_rounded),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    final ok = RegExp(
                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                        .hasMatch(v.trim());
                                    return ok ? null : l.invalidEmail;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        GlassEntrance(
                          delay: GlassMotion.entranceStep * 2,
                          child: _PrimaryCta(
                            label: _saving ? l.saving : l.save,
                            icon: Icons.check_rounded,
                            loading: _saving,
                            onTap: _saving ? null : _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.profileEdit),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
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
          Icons.arrow_back_rounded,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null && !loading ? 0.5 : 1,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4),
                )
              else
                Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
