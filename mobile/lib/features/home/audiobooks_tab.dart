import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Audiobooks tab, Liquid Glass: large in-scroll title, 2-column grid of
/// glass book cards with a frosted price pill over the cover, staggered
/// entrances, and a scroll-reactive top chrome (same pattern as
/// courses_tab.dart). Data still comes from [audiobooksProvider].
class AudiobooksTab extends ConsumerStatefulWidget {
  const AudiobooksTab({super.key});

  @override
  ConsumerState<AudiobooksTab> createState() => _AudiobooksTabState();
}

class _AudiobooksTabState extends ConsumerState<AudiobooksTab> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final books = ref.watch(audiobooksProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AmbientOrbs(),
          books.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(audiobooksProvider),
            ),
            data: (list) {
              return NotificationListener<ScrollNotification>(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.audiobooks,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${list.length} ta audiokitob',
                            style:
                                TextStyle(fontSize: 12.5, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyView(
                          icon: Icons.headphones_rounded,
                          message: l.noAudiobooks,
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => GlassEntrance(
                          delay: GlassMotion.entranceStep * (1 + i),
                          child: _BookCard(book: list[i]),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(offset: _scrollOffset, title: l.audiobooks),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book});
  final Audiobook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final hasCover = book.coverUrl != null && book.coverUrl!.isNotEmpty;
    final coverUrl = hasCover
        ? ref.read(apiClientProvider).resolveMediaUrl(book.coverUrl!)
        : null;

    return GlassPressable(
      onTap: () => context.push('/audiobooks/${book.id}'),
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: coverUrl != null
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _CoverPlaceholder(),
                          )
                        : const _CoverPlaceholder(),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        book.isFree ? l.free : l.forSale,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: book.isFree
                              ? AppColors.success
                              : AppColors.wine,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (book.author?.isNotEmpty ?? false)
                        ? book.author!
                        : l.audiobooks,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.wineDeep],
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white54, size: 44),
      ),
    );
  }
}
