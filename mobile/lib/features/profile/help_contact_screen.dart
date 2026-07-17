import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/brand.dart';

/// Help & contact, Liquid Glass style: gradient banner, glass action cards
/// and frosted contact rows with tinted icon chips.
class HelpContactScreen extends StatefulWidget {
  const HelpContactScreen({super.key});

  @override
  State<HelpContactScreen> createState() => _HelpContactScreenState();
}

class _HelpContactScreenState extends State<HelpContactScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
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
              padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 60),
              children: [
                GlassEntrance(
                  child: Row(
                    children: [
                      _GlassBackButton(onTap: () => context.pop()),
                      Expanded(
                        child: Text(
                          l.helpContact,
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

                // ── Banner ──
                GlassEntrance(
                  delay: GlassMotion.entranceStep,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.wineGradient,
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusCard),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wine.withValues(alpha: 0.30),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
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
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Chat & FAQ action cards ──
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 2,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.chat_rounded,
                            color: dark ? AppColors.wine300 : AppColors.wine,
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
                ),
                const SizedBox(height: 20),

                // ── Quick contact ──
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      l.quickContact.toUpperCase(),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                for (final (i, tile) in [
                  (
                    Icons.telegram_rounded,
                    AppColors.blue,
                    l.contactTelegram,
                    l.telegramHandle,
                    'https://t.me/najotnur_support',
                  ),
                  (
                    Icons.phone_in_talk_rounded,
                    dark ? AppColors.wine300 : AppColors.wine,
                    l.contactPhone,
                    l.supportPhone,
                    'tel:+998712000000',
                  ),
                  (
                    Icons.alternate_email_rounded,
                    AppColors.orange,
                    l.contactEmail,
                    l.supportEmail,
                    'mailto:support@najotnur.uz',
                  ),
                  (
                    Icons.location_on_outlined,
                    AppColors.blue,
                    l.contactAddress,
                    l.supportAddress,
                    null,
                  ),
                ].indexed) ...[
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * (4 + i),
                    child: _ContactTile(
                      icon: tile.$1,
                      color: tile.$2,
                      title: tile.$3,
                      subtitle: tile.$4,
                      url: tile.$5,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 22),
                const Center(child: BrandWordmark(size: 32)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.helpContact),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Widgets ───────────────────────────

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: mutedColor,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: url == null
          ? null
          : () async {
              final uri = Uri.parse(url!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
      child: GlassContainer(
        borderRadius: AppColors.radiusButton,
        withShadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: mutedColor, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (url != null)
              Icon(Icons.open_in_new_rounded, color: mutedColor, size: 18),
          ],
        ),
      ),
    );
  }
}
