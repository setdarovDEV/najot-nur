import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../models/practicum_models.dart';

/// Practicum list card — glass surface with an icon tile, expert-text
/// preview and a "Batafsil" accent row. Navigation is unchanged.
class PracticumInlineCard extends StatelessWidget {
  const PracticumInlineCard({
    super.key,
    required this.practicum,
    this.isLocked = false,
  });
  final Practicum practicum;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final tileColor = dark
        ? AppColors.wine300.withValues(alpha: 0.16)
        : AppColors.wine.withValues(alpha: 0.10);

    return GlassPressable(
      onTap: () => context.push('/practicums/${practicum.id}'),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      Icon(Icons.headphones_rounded, color: accent, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        practicum.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: textColor,
                        ),
                      ),
                      if (practicum.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          practicum.category!,
                          style: TextStyle(color: mutedColor, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isLocked)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        size: 18, color: accent),
                  )
                else if (practicum.expertAudioUrl != null)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.volume_up_rounded,
                        size: 18, color: accent),
                  ),
              ],
            ),
            if (practicum.expertText != null &&
                practicum.expertText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.wine.withValues(alpha: dark ? 0.14 : 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  practicum.expertText!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dark
                        ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
                        : AppColors.inkSoft,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (practicum.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      practicum.category!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  'Batafsil',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
