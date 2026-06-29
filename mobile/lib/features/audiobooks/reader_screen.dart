import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/order_sheet.dart';
import 'audio_handler.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.audiobookId});
  final String audiobookId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  int _page = 0;

  void _onBuyPressed(BuildContext context, Audiobook book) {
    showOrderRequestSheet(
      context,
      purpose: OrderPurpose.audiobook,
      targetId: book.id,
      targetTitle: book.title,
      amount: book.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final book = ref.watch(audiobookDetailProvider(widget.audiobookId));
    final access = ref.watch(audiobookAccessProvider(widget.audiobookId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: book.when(
        loading: () => const _DarkScaffold(
            child:
                Center(child: CircularProgressIndicator(color: Colors.white54))),
        error: (e, _) => Scaffold(
          body: ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(
                audiobookDetailProvider(widget.audiobookId)),
          ),
        ),
        data: (b) {
          // Free book → straight to the player.
          if (b.isFree) {
            final pages = b.pages.isEmpty
                ? [AudiobookPage(pageNumber: 1, content: l.noPage)]
                : b.pages;
            return _PlayerScreen(
              book: b,
              pages: pages,
              pageIndex: _page,
              onPageChanged: (i) => setState(() => _page = i),
            );
          }

          // Paid book → wait for the access check.
          return access.when(
            loading: () => const _DarkScaffold(
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white54))),
            error: (_, __) => _LockedGate(
              book: b,
              onBuy: () => _onBuyPressed(context, b),
              onBack: () => Navigator.of(context).pop(),
            ),
            data: (a) {
              if (a.canRead) {
                final pages = b.pages.isEmpty
                    ? [AudiobookPage(pageNumber: 1, content: l.noPage)]
                    : b.pages;
                return _PlayerScreen(
                  book: b,
                  pages: pages,
                  pageIndex: _page,
                  onPageChanged: (i) => setState(() => _page = i),
                );
              }
              return _LockedGate(
                book: b,
                access: a,
                onBuy: () => _onBuyPressed(context, b),
                onBack: () => Navigator.of(context).pop(),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen audio player
// ---------------------------------------------------------------------------

class _PlayerScreen extends ConsumerStatefulWidget {
  const _PlayerScreen({
    required this.book,
    required this.pages,
    required this.pageIndex,
    required this.onPageChanged,
  });
  final Audiobook book;
  final List<AudiobookPage> pages;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;

  @override
  ConsumerState<_PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<_PlayerScreen> {
  double _speed = 1.0;
  String? _error;
  String? _loadedUrl;
  int _loadedPage = -1;
  bool _nightMode = false;

  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  AudioPlayerHandler get _handler => ref.read(audioHandlerProvider);

  @override
  void initState() {
    super.initState();
    _handler.setSpeed(_speed);
  }

  @override
  void didUpdateWidget(covariant _PlayerScreen old) {
    super.didUpdateWidget(old);
    if (old.pageIndex != widget.pageIndex && _handler.playing) {
      _load(autoplay: true);
    }
  }

  String? _currentUrl() {
    final p = widget.pages[widget.pageIndex];
    if (p.audioUrl != null && p.audioUrl!.isNotEmpty) return p.audioUrl;
    return widget.book.audioUrl;
  }

  Future<void> _load({bool autoplay = false}) async {
    final l = AppLocalizations.of(context);
    final raw = _currentUrl();
    if (raw == null || raw.isEmpty) {
      setState(() => _error = l.noAudioFile);
      return;
    }
    final url = ref.read(apiClientProvider).resolveMediaUrl(raw);
    if (url != _loadedUrl || widget.pageIndex != _loadedPage) {
      try {
        setState(() {
          _error = null;
          _loadedUrl = url;
          _loadedPage = widget.pageIndex;
        });
        final artUri = widget.book.coverUrl != null &&
                widget.book.coverUrl!.isNotEmpty
            ? Uri.tryParse(
                ref.read(apiClientProvider).resolveMediaUrl(widget.book.coverUrl!))
            : null;
        await _handler.loadUrl(
          url,
          title: widget.book.title,
          artist: widget.book.author ?? '',
          artUri: artUri,
        );
        await _handler.setSpeed(_speed);
      } catch (e) {
        setState(() => _error = l.audioLoadError(e.toString()));
        return;
      }
    }
    if (autoplay) await _handler.play();
  }

  Future<void> _togglePlay() async {
    if (_handler.playing) {
      await _handler.pause();
      return;
    }
    await _load();
    if (_error != null) return;
    await _handler.play();
  }

  Future<void> _skip(Duration delta) async {
    if (_error != null) return;
    final pos = _handler.position;
    final dur = _handler.duration ?? Duration.zero;
    final raw = pos + delta;
    final t = raw < Duration.zero ? Duration.zero : (raw > dur ? dur : raw);
    await _handler.seek(t);
  }

  void _cycleSpeed() {
    final i = _speeds.indexOf(_speed);
    final s = _speeds[(i + 1) % _speeds.length];
    setState(() => _speed = s);
    _handler.setSpeed(s);
  }

  void _prevPage() {
    if (widget.pageIndex > 0) widget.onPageChanged(widget.pageIndex - 1);
  }

  void _nextPage() {
    if (widget.pageIndex < widget.pages.length - 1) {
      widget.onPageChanged(widget.pageIndex + 1);
    }
  }

  void _showText(BuildContext ctx) {
    final content = widget.pages[widget.pageIndex].content ?? '';
    if (content.isEmpty) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TextSheet(
        title: widget.book.title,
        page: widget.pageIndex + 1,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final handler = ref.watch(audioHandlerProvider);
    final hasCover = widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty;
    final coverUrl = hasCover
        ? ref.read(apiClientProvider).resolveMediaUrl(widget.book.coverUrl!)
        : null;
    final screenW = MediaQuery.of(context).size.width;
    final coverSize = screenW * 0.68;

    final nightBg = [
      const Color(0xFF0D0407),
      const Color(0xFF070102),
      Colors.black,
    ];
    final dayBg = [AppColors.wine, AppColors.wineDark, AppColors.wineDeep];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.55, 1.0],
            colors: _nightMode ? nightBg : dayBg,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 32),
                    ),
                    Expanded(
                      child: Text(
                        l.audiobooks.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showText(context),
                      icon: const Icon(Icons.article_outlined,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),

              // ── Cover ─────────────────────────────────────────
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: coverSize,
                  height: coverSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.50),
                        blurRadius: 48,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: AppColors.wine.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: coverUrl != null
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _CoverPlaceholder(
                                size: coverSize),
                          )
                        : _CoverPlaceholder(size: coverSize),
                  ),
                ),
              ),
              const Spacer(flex: 2),

              // ── Title + author ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      widget.book.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (widget.book.author != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.book.author!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Page navigator ──────────────────────────────────
              if (widget.pages.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: widget.pageIndex > 0 ? _prevPage : null,
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: widget.pageIndex > 0
                              ? Colors.white
                              : Colors.white24,
                          size: 26,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.pageOfTotal(
                              widget.pageIndex + 1, widget.pages.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            widget.pageIndex < widget.pages.length - 1
                                ? _nextPage
                                : null,
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: widget.pageIndex < widget.pages.length - 1
                              ? Colors.white
                              : Colors.white24,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Seek bar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SeekBar(handler: handler),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 8),

              // ── Controls ─────────────────────────────────────────
              StreamBuilder<PlayerState>(
                stream: handler.playerStateStream,
                builder: (context, snap) {
                  final playing = snap.data?.playing ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Speed
                        _GhostButton(
                          onTap: _cycleSpeed,
                          child: Text(
                            _speed == _speed.truncateToDouble()
                                ? '${_speed.toInt()}.0x'
                                : '${_speed}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // -10s
                        IconButton(
                          onPressed: () =>
                              _skip(const Duration(seconds: -10)),
                          icon: const Icon(Icons.replay_10_rounded,
                              color: Colors.white, size: 34),
                        ),

                        // Play / Pause
                        GestureDetector(
                          onTap: _togglePlay,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _nightMode
                                  ? AppColors.wine
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _nightMode
                                      ? AppColors.wine.withValues(alpha: 0.40)
                                      : Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: _nightMode
                                  ? Colors.white
                                  : AppColors.wine,
                              size: 40,
                            ),
                          ),
                        ),

                        // +10s
                        IconButton(
                          onPressed: () =>
                              _skip(const Duration(seconds: 10)),
                          icon: const Icon(Icons.forward_10_rounded,
                              color: Colors.white, size: 34),
                        ),

                        // Night mode toggle
                        _GhostButton(
                          onTap: () =>
                              setState(() => _nightMode = !_nightMode),
                          active: _nightMode,
                          child: Icon(
                            _nightMode
                                ? Icons.bedtime_rounded
                                : Icons.bedtime_outlined,
                            color: _nightMode
                                ? AppColors.blue
                                : Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seekable slider — white on dark
// ---------------------------------------------------------------------------

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.handler});
  final AudioPlayerHandler handler;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.handler.positionStream,
      builder: (_, posSnap) {
        final pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: widget.handler.durationStream,
          builder: (_, durSnap) {
            final dur = durSnap.data;
            final maxMs = (dur?.inMilliseconds ?? 0).toDouble();
            final curMs = _drag ??
                (maxMs == 0
                    ? 0.0
                    : pos.inMilliseconds
                        .clamp(0, maxMs.toInt())
                        .toDouble());
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.28),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: Slider(
                    value: maxMs == 0 ? 0 : curMs.clamp(0, maxMs),
                    min: 0,
                    max: maxMs == 0 ? 1 : maxMs,
                    onChanged:
                        maxMs == 0 ? null : (v) => setState(() => _drag = v),
                    onChangeEnd: maxMs == 0
                        ? null
                        : (v) {
                            widget.handler
                                .seek(Duration(milliseconds: v.toInt()));
                            setState(() => _drag = null);
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(Duration(milliseconds: curMs.toInt())),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      StreamBuilder<PlayerState>(
                        stream: widget.handler.playerStateStream,
                        builder: (_, s) {
                          final loading =
                              s.data?.processingState == ProcessingState.loading ||
                                  s.data?.processingState ==
                                      ProcessingState.buffering;
                          if (loading) {
                            return const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white54,
                              ),
                            );
                          }
                          return Text(
                            dur == null ? '--:--' : _fmt(dur),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _DarkScaffold extends StatelessWidget {
  const _DarkScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.wineDeep,
        body: child,
      );
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB0294A), AppColors.wineDeep],
          ),
        ),
        child: const Icon(Icons.menu_book_rounded,
            color: Colors.white30, size: 80),
      );
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.onTap,
    required this.child,
    this.active = false,
  });
  final VoidCallback onTap;
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.blue.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: active
                ? Border.all(color: AppColors.blue.withValues(alpha: 0.50), width: 1.2)
                : null,
          ),
          child: child,
        ),
      );
}

// ---------------------------------------------------------------------------
// Matn bottom sheet
// ---------------------------------------------------------------------------

class _TextSheet extends StatelessWidget {
  const _TextSheet({
    required this.title,
    required this.page,
    required this.content,
  });
  final String title;
  final int page;
  final String content;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF6EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.wine100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bet $page',
                      style: const TextStyle(
                        color: AppColors.wine,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.9,
                      color: Color(0xFF2C2622),
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

// ---------------------------------------------------------------------------
// Locked gate
// ---------------------------------------------------------------------------

class _LockedGate extends StatelessWidget {
  const _LockedGate({
    required this.onBuy,
    required this.onBack,
    required this.book,
    this.access,
  });
  final VoidCallback onBuy;
  final VoidCallback onBack;
  final Audiobook book;
  final AudiobookAccessStatus? access;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasPending = access?.hasPendingOrder ?? false;
    final priceLabel = l.sumPrice(book.price.toStringAsFixed(0));

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 64),
              const SizedBox(height: 24),
              Text(book.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(priceLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  hasPending
                      ? l.audiobookOrderPending
                      : l.buyAudiobookPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hasPending ? null : onBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.wine,
                      disabledBackgroundColor: Colors.white24,
                      disabledForegroundColor: Colors.white60,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    child: Text(hasPending ? l.orderPending : l.buy),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onBack,
                child: Text(l.back,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
