import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';

/// FAQ, Liquid Glass style: glass back header + expandable frosted rows.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
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
    final topInset = MediaQuery.of(context).padding.top;
    final faqs = [
      (q: l.faq1Q, a: l.faq1A),
      (q: l.faq2Q, a: l.faq2A),
      (q: l.faq3Q, a: l.faq3A),
      (q: l.faq4Q, a: l.faq4A),
    ];

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
                          l.faqTitle,
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
                const SizedBox(height: 12),
                for (var i = 0; i < faqs.length; i++) ...[
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * (1 + i),
                    child:
                        _FaqTile(question: faqs[i].q, answer: faqs[i].a),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(offset: _scrollOffset, title: l.faqTitle),
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

/// Expandable glass row: chevron rotates, answer settles in with AnimatedSize.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassPressable(
      onTap: () => setState(() => _open = !_open),
      child: GlassContainer(
        borderRadius: AppColors.radiusButton,
        withShadow: _open,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      height: 1.35,
                      color: _open ? accent : textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: GlassMotion.pressOut,
                  curve: GlassMotion.pressOutCurve,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: mutedColor),
                ),
              ],
            ),
            AnimatedSize(
              duration: GlassMotion.pressOut,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        widget.answer,
                        style: TextStyle(
                          color: dark
                              ? AppColors.inkDarkPrimary
                                  .withValues(alpha: 0.78)
                              : AppColors.inkSoft,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
