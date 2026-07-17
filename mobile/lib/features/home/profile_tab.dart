import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/brand.dart';

/// Profile tab, Liquid Glass mockup "3c": avatar with glass ring, a featured
/// certificates card, then grouped glass settings rows with icon chips and
/// hairline separators. Logout stays in [AppColors.danger].
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.logoutConfirmNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.logoutConfirmYes),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AmbientOrbs(),
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical) {
                _scrollOffset.value = n.metrics.pixels;
              }
              return false;
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 150),
              children: [
                GlassEntrance(
                  child: Text(
                    l.profile,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GlassEntrance(
                  delay: GlassMotion.entranceStep,
                  child: _IdentityRow(
                    name: auth.isLoggedIn
                        ? (auth.user?.displayName ?? l.user)
                        : l.guest,
                    detail:
                        auth.user?.phone ?? auth.user?.email ?? l.notRegistered,
                    loggedIn: auth.isLoggedIn,
                    editLabel: l.edit,
                    onEdit: () => context.push('/profile/edit'),
                  ),
                ),
                const SizedBox(height: 14),
                if (!auth.isLoggedIn) ...[
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * 2,
                    child: _LoginPromptCard(
                      label: l.registerLogin,
                      onTap: () => context.push('/auth'),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 2,
                  child: _FeaturedRow(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: AppColors.warning,
                    title: l.certificates,
                    subtitle: l.certificatesSubtitle,
                    onTap: () => context.push('/profile/certificates'),
                  ),
                ),
                const SizedBox(height: 16),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'SOZLAMALAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 4,
                  child: _ThemeModeRow(
                    isDark: ref.watch(themeModeProvider) == ThemeMode.dark ||
                        (ref.watch(themeModeProvider) == ThemeMode.system &&
                            dark),
                    onChanged: (v) => ref
                        .read(themeModeProvider.notifier)
                        .setMode(v ? ThemeMode.dark : ThemeMode.light),
                  ),
                ),
                const SizedBox(height: 10),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 4,
                  child: _MenuGroup(
                    rows: [
                      _MenuRowData(
                        icon: Icons.receipt_long_rounded,
                        color: dark ? AppColors.wine300 : AppColors.wine,
                        title: l.myOrders,
                        subtitle: l.myOrdersSubtitle,
                        onTap: () => context.push('/profile/orders'),
                      ),
                      _MenuRowData(
                        icon: Icons.history_rounded,
                        color: AppColors.blue,
                        title: l.analysisHistory,
                        subtitle: l.historySubtitle,
                        onTap: () => context.push('/profile/history'),
                      ),
                      _MenuRowData(
                        icon: Icons.notifications_none_rounded,
                        color: AppColors.orange,
                        title: l.notifications,
                        subtitle: l.notificationsSubtitle,
                        onTap: () => context.push('/profile/notifications'),
                      ),
                      _MenuRowData(
                        icon: Icons.language_rounded,
                        color: AppColors.success,
                        title: l.language,
                        subtitle: l.changeLanguageSubtitle,
                        onTap: () => context.push('/language'),
                      ),
                      _MenuRowData(
                        icon: Icons.help_outline_rounded,
                        color: dark ? AppColors.wine300 : AppColors.wine,
                        title: l.helpContact,
                        subtitle: l.helpSubtitle,
                        onTap: () => context.push('/profile/help'),
                      ),
                    ],
                  ),
                ),
                if (auth.isLoggedIn) ...[
                  const SizedBox(height: 14),
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * 5,
                    child: _LogoutRow(
                      label: l.logout,
                      onTap: _confirmLogout,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                const Center(child: BrandWordmark(size: 34)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l.appVersion('1.0.0'),
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(offset: _scrollOffset, title: l.profile),
          ),
        ],
      ),
    );
  }
}

/// Avatar with a subtle glass ring + name/phone + "edit" chip (mockup 3c).
class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.name,
    required this.detail,
    required this.loggedIn,
    required this.editLabel,
    required this.onEdit,
  });

  final String name;
  final String detail;
  final bool loggedIn;
  final String editLabel;
  final VoidCallback onEdit;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase());
    return parts.isEmpty ? '?' : parts.join();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.wineGradient,
              border: Border.all(
                color: dark
                    ? AppColors.glassHighlightDark
                    : AppColors.glassHighlightLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wine.withValues(alpha: 0.30),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: loggedIn
                ? Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(Icons.person_rounded,
                    color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: mutedColor),
                ),
              ],
            ),
          ),
          if (loggedIn) ...[
            const SizedBox(width: 8),
            GlassPressable(
              onTap: onEdit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.wine300.withValues(alpha: 0.16)
                      : AppColors.wine100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  editLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Logged-out state: gradient CTA on a glass card.
class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.login_rounded, color: Colors.white, size: 19),
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
    );
  }
}

/// Featured glass row (certificates card in mockup 3c).
class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuRowData {
  const _MenuRowData({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

/// Grouped glass card: icon chip + label + chevron rows with hairline
/// separators (mockup 3c settings list).
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.rows});
  final List<_MenuRowData> rows;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final hairline = dark ? AppColors.lineDark : AppColors.line;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            GlassPressable(
              onTap: rows[i].onTap,
              child: Container(
                decoration: BoxDecoration(
                  border: i == rows.length - 1
                      ? null
                      : Border(
                          bottom: BorderSide(color: hairline, width: 0.5),
                        ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: rows[i].color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(rows[i].icon, color: rows[i].color, size: 17),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[i].title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          if (rows[i].subtitle != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              rows[i].subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: mutedColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: mutedColor, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Tungi rejim" switch row (mockup 5c's springy glass switch).
class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({required this.isDark, required this.onChanged});
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: accent,
              size: 17,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'Tungi rejim',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          Switch.adaptive(
            value: isDark,
            onChanged: onChanged,
            activeTrackColor: AppColors.wine,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// Logout glass row, centered danger label (mockup 5c).
class _LogoutRow extends StatelessWidget {
  const _LogoutRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        withShadow: false,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded,
                color: AppColors.danger, size: 17),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
