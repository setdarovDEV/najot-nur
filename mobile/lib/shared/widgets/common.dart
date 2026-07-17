import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import 'brand.dart';

/// Shared state widgets, Liquid Glass mockup "6d": empty / error / loading
/// states as frosted glass cards with soft icon circles.

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark ? AppColors.glassFillDark : AppColors.glassFillLight,
              border: Border.all(
                color: dark
                    ? AppColors.glassStrokeDark
                    : AppColors.glassStrokeLight,
                width: 0.5,
              ),
            ),
            child: const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: AppColors.wine,
                strokeWidth: 3,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: mutedColor)),
          ],
        ],
      ),
    );
  }
}

/// Error state (mockup 6d "tarmoq xatosi"): danger-tinted glass card whose
/// icon circle shakes in on appear, plus a tinted retry pill.
class ErrorView extends StatefulWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: GlassMotion.errorShake,
  )..forward();

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassEntrance(
          child: Stack(
            children: [
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) {
                        final t = _shake.value;
                        // Damped horizontal shake, settling at 0.
                        final dx = (1 - t) *
                            8 *
                            (t * 20).remainder(2) *
                            ((t * 20).floor().isEven ? 1 : -1);
                        return Transform.translate(
                            offset: Offset(dx, 0), child: child);
                      },
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger.withValues(alpha: 0.12),
                        ),
                        child: const Icon(Icons.wifi_off_rounded,
                            size: 28, color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: textColor,
                      ),
                    ),
                    if (widget.onRetry != null) ...[
                      const SizedBox(height: 14),
                      GlassPressable(
                        onTap: widget.onRetry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l.retry,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Danger-tinted ring over the glass surface (mockup 6d).
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusCard),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.35),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state (mockup 6d "bo'sh ro'yxat"): glass card with a soft tinted
/// icon circle, bold title and muted subtitle.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.subtitle,
  });
  final String message;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassEntrance(
          child: GlassContainer(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark
                        ? AppColors.wine300.withValues(alpha: 0.16)
                        : AppColors.wine.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, size: 28, color: accent),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: mutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PillTag extends StatelessWidget {
  const PillTag(this.text, {super.key, this.color = AppColors.wine, this.bg});
  final String text;
  final Color color;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Wraps a screen that requires the user to be logged in.
/// Shows a friendly "please sign in" page instead of the content when anonymous.
class LoginGuard extends ConsumerWidget {
  const LoginGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    if (isLoggedIn) return child;

    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassEntrance(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandBadge(size: 80, radius: 22),
                          const SizedBox(height: 20),
                          Text(
                            l.loginRequiredTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l.loginRequiredSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mutedColor,
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GlassPressable(
                            onTap: () => context.push('/auth'),
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppColors.wineGradient,
                                borderRadius: BorderRadius.circular(
                                    AppColors.radiusButton),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.wine
                                        .withValues(alpha: 0.30),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Text(
                                l.registerLogin,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () {
                              if (context.canPop()) context.pop();
                            },
                            child: Text(
                              l.back,
                              style: TextStyle(color: mutedColor),
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
        ],
      ),
    );
  }
}

/// Bottom sheet shown when an anonymous user tries to view gated results.
Future<void> showLoginRequiredSheet(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetScrim,
    isScrollControlled: true,
    builder: (ctx) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
      final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
      return GlassSheet(
        padding: EdgeInsets.fromLTRB(
            24, 10, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 18),
            const BrandBadge(size: 64),
            const SizedBox(height: 20),
            Text(
              l.loginRequiredTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.loginRequiredSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GlassPressable(
                onTap: () {
                  Navigator.pop(ctx);
                  ctx.push('/auth');
                },
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.wineGradient,
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusButton),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wine.withValues(alpha: 0.30),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Text(
                    l.registerLogin,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
