import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';

/// Home tab, Liquid Glass mockup "1a/1b": gradient hero with the speech
/// action card overlapping it, a 2×2 glass section grid, and a recommended
/// course + audiobook pulled from the live catalog. Ambient orbs drift
/// behind everything; a glass top chrome fades in on scroll.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key, this.onChangeTab});

  final ValueChanged<int>? onChangeTab;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
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

    return Stack(
      children: [
        const AmbientOrbs(),
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical) {
              _scrollOffset.value = n.metrics.pixels;
            }
            return false;
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final auth = ref.watch(authControllerProvider);
                    return _Hero(
                      isLoggedIn: auth.isLoggedIn,
                      name: auth.user?.displayName,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Speech action card overlaps the hero (mockup: -42px).
                      Transform.translate(
                        offset: const Offset(0, -42),
                        child: GlassEntrance(
                          delay: GlassMotion.entranceStep,
                          child: _SpeechCard(
                            title: l.homeActionSpeech,
                            subtitle: l.homeActionSpeechSub,
                            onTap: () => context.push('/speech'),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
                              child: Text(
                                l.homeFeatures,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                            _SectionsGrid(onChangeTab: widget.onChangeTab),
                            const SizedBox(height: 22),
                            _RecommendedSection(
                              textColor: textColor,
                              mutedColor: mutedColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlassTopChrome(offset: _scrollOffset, title: 'NotiqAI'),
        ),
      ],
    );
  }
}

// ───────────────────────── Hero ─────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.isLoggedIn, this.name});
  final bool isLoggedIn;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return GlassEntrance(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 66),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.58, 1.0],
            colors: [AppColors.wine, AppColors.wineDark, AppColors.wineDeep],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppColors.radiusHero),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              right: -20,
              bottom: -66,
              child: CustomPaint(
                size: const Size(double.infinity, 70),
                painter: _WavePainter(),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.homeGreeting,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.homeSubtitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoggedIn)
                  _HeroGlassBadge(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (name?.isNotEmpty ?? false)
                              ? name!.characters.first.toUpperCase()
                              : 'N',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(20, 6),
                          painter: _MiniWavePainter(),
                        ),
                      ],
                    ),
                  )
                else
                  GlassPressable(
                    onTap: () => context.push('/auth'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                          width: 0.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FFFFFF),
                            offset: Offset(0, 1),
                            blurRadius: 0,
                            spreadRadius: -0.5,
                            blurStyle: BlurStyle.inner,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.login_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            l.login,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular translucent badge in the hero's top-right (mockup: "N" + wave).
class _HeroGlassBadge extends StatelessWidget {
  const _HeroGlassBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

/// The two decorative voice-wave strokes along the hero's bottom edge.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final p1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final p2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Path wave(double y) {
      final path = Path()..moveTo(0, y);
      path.quadraticBezierTo(w * 0.25, y - 30, w * 0.5, y);
      path.quadraticBezierTo(w * 0.75, y + 30, w, y);
      return path;
    }

    canvas.drawPath(wave(40), p1);
    canvas.drawPath(wave(56), p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()..moveTo(0, size.height / 2);
    path.quadraticBezierTo(
        size.width * 0.25, 0, size.width * 0.5, size.height / 2);
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────── Speech action card ─────────────────────────

class _SpeechCard extends StatelessWidget {
  const _SpeechCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
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
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.wineGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mutedColor, size: 22),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Sections grid ─────────────────────────

class _SectionsGrid extends ConsumerWidget {
  const _SectionsGrid({this.onChangeTab});
  final ValueChanged<int>? onChangeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final items = [
      (
        icon: Icons.play_circle_fill_rounded,
        color: AppColors.wine,
        title: l.videoLessons,
        subtitle: l.tabCourses,
        onTap: () => onChangeTab?.call(1),
      ),
      (
        icon: Icons.headphones_rounded,
        color: AppColors.blue,
        title: l.audiobooks,
        subtitle: l.tabBooks,
        onTap: () => onChangeTab?.call(2),
      ),
      (
        icon: Icons.psychology_rounded,
        color: AppColors.orange,
        title: l.psychologyTest,
        subtitle: l.psychologyAnalysis,
        onTap: () => context.push('/psychology'),
      ),
      (
        icon: Icons.visibility_rounded,
        color: AppColors.success,
        title: l.homeActionObservation,
        subtitle: l.homeActionObservationSub,
        onTap: () => context.push('/observation'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return GlassEntrance(
          delay: GlassMotion.entranceStep * (3 + i),
          child: _SectionCard(
            icon: item.icon,
            color: item.color,
            title: item.title,
            subtitle: item.subtitle,
            onTap: item.onTap,
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Recommended ─────────────────────────

class _RecommendedSection extends ConsumerWidget {
  const _RecommendedSection({
    required this.textColor,
    required this.mutedColor,
  });
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final courses = ref.watch(coursesProvider).valueOrNull;
    final books = ref.watch(audiobooksProvider).valueOrNull;
    final course = (courses != null && courses.isNotEmpty) ? courses.first : null;
    final book = (books != null && books.isNotEmpty) ? books.first : null;
    if (course == null && book == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
          child: Text(
            l.homeRecommended,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
        if (course != null) ...[
          GlassEntrance(
            delay: GlassMotion.entranceStep * 7,
            child: _CourseCard(course: course),
          ),
          const SizedBox(height: 12),
        ],
        if (book != null)
          GlassEntrance(
            delay: GlassMotion.entranceStep * 8,
            child: _AudiobookRow(book: book),
          ),
      ],
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final coverUrl = course.coverUrl == null
        ? null
        : ref.read(apiClientProvider).resolveMediaUrl(course.coverUrl!);

    return GlassPressable(
      onTap: () => context.push('/courses/${course.id}'),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _CoverFallback(),
                      )
                    : const _CoverFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.lessonsShort(course.lessons.length),
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: course.isFree ? null : AppColors.wineGradient,
                      color: course.isFree
                          ? AppColors.success.withValues(alpha: 0.12)
                          : null,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: course.isFree
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.wine.withValues(alpha: 0.30),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Text(
                      course.isFree
                          ? l.free
                          : l.sumPrice(course.price.toStringAsFixed(0)),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color:
                            course.isFree ? AppColors.success : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.wine.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_circle_outline_rounded,
        size: 40,
        color: AppColors.wine.withValues(alpha: 0.4),
      ),
    );
  }
}

class _AudiobookRow extends StatelessWidget {
  const _AudiobookRow({required this.book});
  final Audiobook book;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: () => context.push('/audiobooks/${book.id}'),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.18),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.blue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (book.author?.isNotEmpty ?? false) book.author!,
                      l.audiobooks,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (book.isFree)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.free,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
