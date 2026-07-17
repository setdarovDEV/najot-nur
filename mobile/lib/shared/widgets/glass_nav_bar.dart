import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';

/// One destination in a [GlassNavBar].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating Liquid Glass bottom navigation — a translucent pill that sits
/// off the screen edges (mockup panel "1e") instead of a docked opaque bar.
/// The active-tab indicator morphs position/width with a small overshoot
/// (`GlassMotion.tabMorph`) and confirms the switch with a selection haptic.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = dark ? AppColors.accentDark : AppColors.wine;
    final inactiveColor = dark ? AppColors.mutedDark : AppColors.muted;
    final indicatorColor =
        dark ? AppColors.wine300.withValues(alpha: 0.22) : AppColors.wine.withValues(alpha: 0.14);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      top: false,
      child: GlassContainer(
        tier: GlassTier.chrome,
        borderRadius: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: GlassMotion.tabMorph,
                    curve: GlassMotion.tabMorphCurve,
                    left: itemWidth * selectedIndex,
                    width: itemWidth,
                    top: 6,
                    bottom: 6,
                    child: Center(
                      child: Container(
                        width: itemWidth - 14,
                        height: 48,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (i) {
                      final active = i == selectedIndex;
                      final item = items[i];
                      return Expanded(
                        child: GlassPressable(
                          haptic: false,
                          onTap: () {
                            if (i != selectedIndex) {
                              HapticFeedback.selectionClick();
                              onSelect(i);
                            }
                          },
                          child: SizedBox(
                            height: 60,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  active ? item.activeIcon : item.icon,
                                  color: active ? activeColor : inactiveColor,
                                  size: 22,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: active ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
