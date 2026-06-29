import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Self-contained Najot Nur emblem badge (white mark on a wine field).
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, this.size = 56, this.radius = 16});
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: Image.asset('assets/images/logo_white.png', fit: BoxFit.contain),
      ),
    );
  }
}

/// Emblem + wordmark lockup. [onDark] switches text to white.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.onDark = false, this.size = 44});
  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : AppColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandBadge(size: size, radius: size * 0.28),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Najot Nur',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'notiqlik mahorati markazi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size * 0.22,
                  color: onDark ? Colors.white70 : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
