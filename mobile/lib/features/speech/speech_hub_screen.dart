import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';

/// Speech hub, Liquid Glass style: ambient orbs, glass back header and two
/// glass action cards with gradient icon chips.
class SpeechHubScreen extends StatefulWidget {
  const SpeechHubScreen({super.key});

  @override
  State<SpeechHubScreen> createState() => _SpeechHubScreenState();
}

class _SpeechHubScreenState extends State<SpeechHubScreen> {
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
                          l.speechCheck,
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
                const SizedBox(height: 18),
                GlassEntrance(
                  delay: GlassMotion.entranceStep,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.speechHubPrompt,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.speechHubSub,
                        style: TextStyle(
                            fontSize: 13, height: 1.4, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 2,
                  child: _Option(
                    icon: Icons.mic_rounded,
                    title: l.voiceCheck,
                    description: l.voiceCheckDesc,
                    gradient: AppColors.wineGradient,
                    onTap: () => context.push('/speech/voice'),
                  ),
                ),
                const SizedBox(height: 12),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 3,
                  child: _Option(
                    icon: Icons.forum_rounded,
                    title: l.speechAnalysis,
                    description: l.speechAnalysisDesc,
                    gradient: const LinearGradient(
                      colors: [AppColors.blue, AppColors.wine],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => context.push('/speech/talk'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(offset: _scrollOffset, title: l.speechCheck),
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

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                        color: mutedColor, height: 1.35, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
