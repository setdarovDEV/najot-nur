import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

class AudiobooksTab extends ConsumerWidget {
  const AudiobooksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final books = ref.watch(audiobooksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.audiobooks), titleSpacing: 20),
      body: books.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(audiobooksProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.headphones_rounded,
              message: l.noAudiobooks,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _BookCard(book: list[i]),
          );
        },
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book});
  final Audiobook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/audiobooks/${book.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Cover(
              coverUrl: book.coverUrl,
              isFree: book.isFree,
              resolver: ref.read(apiClientProvider).resolveMediaUrl,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (book.author != null)
            Text(
              book.author!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.coverUrl,
    required this.isFree,
    required this.resolver,
  });
  final String? coverUrl;
  final bool isFree;
  final String Function(String) resolver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    final fallback = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.wine, AppColors.wineDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white54,
        size: 48,
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasCover)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              resolver(coverUrl!),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return fallback;
              },
              errorBuilder: (_, __, ___) => fallback,
            ),
          )
        else
          fallback,
        Positioned(
          top: 10,
          left: 10,
          child: PillTag(
            isFree ? l.free : l.forSale,
            color: Colors.white,
            bg: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
