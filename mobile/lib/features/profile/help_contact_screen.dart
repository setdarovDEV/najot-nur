import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/brand.dart';

class HelpContactScreen extends StatelessWidget {
  const HelpContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.helpContact), titleSpacing: 20),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Banner ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.wineGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const BrandBadge(size: 56, radius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.contactBannerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.contactBannerSubtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Chat & FAQ action cards ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.chat_rounded,
                    color: AppColors.wine,
                    title: l.supportChatTitle,
                    subtitle: l.chatActionSubtitle,
                    onTap: () => context.push('/profile/chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.orange,
                    title: l.faqTitle,
                    subtitle: l.faqActionSubtitle,
                    onTap: () => context.push('/profile/faq'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Quick contact ──
          _SectionLabel(l.quickContact),
          _ContactTile(
            icon: Icons.telegram_rounded,
            color: const Color(0xFF27A2E0),
            title: l.contactTelegram,
            subtitle: l.telegramHandle,
            url: 'https://t.me/najotnur_support',
          ),
          _ContactTile(
            icon: Icons.phone_in_talk_rounded,
            color: AppColors.wine,
            title: l.contactPhone,
            subtitle: l.supportPhone,
            url: 'tel:+998712000000',
          ),
          _ContactTile(
            icon: Icons.alternate_email_rounded,
            color: AppColors.orange,
            title: l.contactEmail,
            subtitle: l.supportEmail,
            url: 'mailto:support@najotnur.uz',
          ),
          _ContactTile(
            icon: Icons.location_on_outlined,
            color: AppColors.blue,
            title: l.contactAddress,
            subtitle: l.supportAddress,
            url: null,
          ),
          const SizedBox(height: 32),
          const Center(child: BrandWordmark(size: 32)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────── Widgets ───────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? url;

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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        trailing: url == null
            ? null
            : const Icon(Icons.open_in_new_rounded, color: AppColors.muted),
        onTap: url == null
            ? null
            : () async {
                final uri = Uri.parse(url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
      ),
    );
  }
}
