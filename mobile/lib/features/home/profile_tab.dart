import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/brand.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.profile), titleSpacing: 20),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.wineGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child:
                      Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.isLoggedIn
                            ? (auth.user?.displayName ?? l.user)
                            : l.guest,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.user?.phone ??
                            auth.user?.email ??
                            l.notRegistered,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (auth.isLoggedIn)
                  IconButton(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    tooltip: l.edit,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!auth.isLoggedIn)
            ElevatedButton.icon(
              onPressed: () => context.push('/auth'),
              icon: const Icon(Icons.login_rounded),
              label: Text(l.registerLogin),
            ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.receipt_long_rounded,
            title: l.myOrders,
            subtitle: l.myOrdersSubtitle,
            onTap: () => context.push('/profile/orders'),
          ),
          _MenuTile(
            icon: Icons.history_rounded,
            title: l.analysisHistory,
            subtitle: l.historySubtitle,
            onTap: () => context.push('/profile/history'),
          ),
          _MenuTile(
            icon: Icons.workspace_premium_rounded,
            title: l.certificates,
            subtitle: l.certificatesSubtitle,
            onTap: () => context.push('/profile/certificates'),
          ),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            title: l.notifications,
            subtitle: l.notificationsSubtitle,
            onTap: () => context.push('/profile/notifications'),
          ),
          _MenuTile(
            icon: Icons.language_rounded,
            title: l.language,
            subtitle: l.changeLanguageSubtitle,
            onTap: () => context.push('/language'),
          ),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            title: l.helpContact,
            subtitle: l.helpSubtitle,
            onTap: () => context.push('/profile/help'),
          ),
          if (auth.isLoggedIn) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
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
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        child: Text(l.logoutConfirmYes),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: Text(
                l.logout,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Center(child: BrandWordmark(size: 34)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l.appVersion('1.0.0'),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.wine100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.wine, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 12)),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}
