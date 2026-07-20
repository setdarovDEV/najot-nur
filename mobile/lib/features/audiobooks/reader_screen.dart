
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
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

    return book.when(
      loading: () => const _GlassScaffold(child: AppLoader()),
      error: (e, _) => _GlassScaffold(
        child: ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(audiobookDetailProvider(widget.audiobookId)),
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
          loading: () => const _GlassScaffold(child: AppLoader()),
          error: (_, __) => _GlassScaffold(
            child: ErrorView(
              message:
                  'Kirish tekshirishda xatolik. Qaytadan urinib ko\'ring.',
              onRetry: () => ref
                  .invalidate(audiobookAccessProvider(widget.audiobookId)),
            ),
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
    );
  }
}

/// Loading / error shell — ambient orbs behind whatever [child] shows.
class _GlassScaffold extends StatelessWidget {
  const _GlassScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [const AmbientOrbs(), child],
        ),
      );
}

// ---------------------------------------------------------------------------
// Full-screen audio player — Liquid Glass mockup "3a": light glass surfaces
// over ambient orbs, a big wine glow behind the rounded cover, gradient
// progress bar, glass control circles and a glass page list card.
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
        setState(() => _error = null);
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
        setState(() {
          _loadedUrl = url;
          _loadedPage = widget.pageIndex;
        });
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

  void _showText(BuildContext ctx) {
    final content = widget.pages[widget.pageIndex].content ?? '';
    if (content.isEmpty) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.sheetScrim,
      builder: (_) => _TextSheet(
        title: widget.book.title,
        page: widget.pageIndex + 1,
        content: content,
      ),
    );
  }

  String get _speedLabel => _speed == _speed.truncateToDouble()
      ? '${_speed.toInt()}.0×'
      : '$_speed×';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final handler = ref.watch(audioHandlerProvider);
    final baseTheme = Theme.of(context);
    // "Uyqu" (night) mode forces the dark glass tokens on this screen only —
    // the whole subtree re-reads Theme.brightness, so everything flips.
    final theme = _nightMode && baseTheme.brightness == Brightness.light
        ? baseTheme.copyWith(
            colorScheme:
                baseTheme.colorScheme.copyWith(brightness: Brightness.dark),
          )
        : baseTheme;
    final dark = theme.brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    final hasCover =
        widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty;
    final coverUrl = hasCover
        ? ref.read(apiClientProvider).resolveMediaUrl(widget.book.coverUrl!)
        : null;
    final screenW = MediaQuery.of(context).size.width;
    final coverSize = (screenW * 0.58).clamp(180.0, 260.0);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: dark ? AppColors.bgDark : AppColors.bg,
      resizeToAvoidBottomInset: false,
      body: Theme(
        data: theme,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                color: dark ? AppColors.bgDark : AppColors.bg,
              ),
            ),
            // Big wine glow behind the cover (mockup 3a).
            const _CoverGlow(),
            const AmbientOrbs(),
            // Mirrors the cover glow at the bottom so the ambient look
            // still reaches the far edge on short (single-page) books.
            const _BottomGlow(),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 40),
              child: Column(
                children: [
                  // ── Top chrome ─────────────────────────────────
                  GlassEntrance(
                    child: Row(
                      children: [
                        _GlassCircleButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            l.audiobooks.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        _GlassCircleButton(
                          icon: Icons.article_outlined,
                          onTap: () => _showText(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Cover ──────────────────────────────────────
                  GlassEntrance(
                    delay: GlassMotion.entranceStep,
                    child: Container(
                      width: coverSize,
                      height: coverSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(44),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.wineDeep.withValues(alpha: 0.35),
                            blurRadius: 50,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(44),
                        child: coverUrl != null
                            ? Image.network(
                                coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _CoverPlaceholder(),
                              )
                            : const _CoverPlaceholder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title + author ─────────────────────────────
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * 2,
                    child: Column(
                      children: [
                        Text(
                          widget.book.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              if (widget.book.author?.isNotEmpty ?? false)
                                TextSpan(text: widget.book.author!),
                              if ((widget.book.author?.isNotEmpty ?? false) &&
                                  widget.book.isFree)
                                const TextSpan(text: ' · '),
                              if (widget.book.isFree)
                                TextSpan(
                                  text: l.free,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Progress ───────────────────────────────────
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * 3,
                    child: _SeekBar(handler: handler),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Controls ───────────────────────────────────
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * 4,
                    child: StreamBuilder<PlayerState>(
                      stream: handler.playerStateStream,
                      builder: (context, snap) {
                        final playing = snap.data?.playing ?? false;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _GlassPill(
                              onTap: _cycleSpeed,
                              child: Text(
                                _speedLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                            _SkipButton(
                              forward: false,
                              onTap: () =>
                                  _skip(const Duration(seconds: -15)),
                            ),
                            // Play / pause
                            GlassPressable(
                              onTap: _togglePlay,
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  gradient: AppColors.wineGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.wine
                                          .withValues(alpha: 0.40),
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ),
                            _SkipButton(
                              forward: true,
                              onTap: () => _skip(const Duration(seconds: 15)),
                            ),
                            _GlassPill(
                              onTap: () =>
                                  setState(() => _nightMode = !_nightMode),
                              active: _nightMode,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _nightMode
                                        ? Icons.bedtime_rounded
                                        : Icons.bedtime_outlined,
                                    size: 14,
                                    color: _nightMode
                                        ? AppColors.blue
                                        : textColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Uyqu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _nightMode
                                          ? AppColors.blue
                                          : textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // ── Page list ──────────────────────────────────
                  if (widget.pages.length > 1) ...[
                    const SizedBox(height: 18),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep * 5,
                      child: GlassContainer(
                        borderRadius: AppColors.radiusTariffCard,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < widget.pages.length; i++)
                              _PageRow(
                                index: i,
                                page: widget.pages[i],
                                active: i == widget.pageIndex,
                                isLast: i == widget.pages.length - 1,
                                onTap: () {
                                  if (i != widget.pageIndex) {
                                    widget.onPageChanged(i);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft glow anchored to the bottom edge so the ambient background reaches
/// the far end of the page even when there's little content (e.g. a
/// single-page free book) below the fold.
class _BottomGlow extends StatelessWidget {
  const _BottomGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -160,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 480,
            height: 480,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.orange.withValues(alpha: 0.22),
                  AppColors.orange.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.85],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The big wine radial glow the mockup places behind the cover.
class _CoverGlow extends StatelessWidget {
  const _CoverGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          // Soft-stopped gradient instead of ImageFiltered blur — same glow,
          // no per-frame GPU filter cost.
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.wine.withValues(alpha: 0.35),
                  AppColors.wine.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.85],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});
  final IconData icon;
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
          icon,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.inkSoft,
        ),
      ),
    );
  }
}

/// Small frosted pill (speed / "Uyqu").
class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    required this.onTap,
    this.active = false,
  });
  final Widget child;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.blue.withValues(alpha: 0.18)
              : (dark ? AppColors.glassFillDark : AppColors.glassFillLight),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? AppColors.blue.withValues(alpha: 0.50)
                : (dark
                    ? AppColors.glassStrokeDark
                    : AppColors.glassStrokeLight),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// ±15s glass circle with the tiny "15" caption (mockup 3a).
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.forward, required this.onTap});
  final bool forward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = dark ? AppColors.inkDarkPrimary : AppColors.inkSoft;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AppColors.glassFillDark : AppColors.glassFillLight,
          border: Border.all(
            color:
                dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.flip(
              flipX: forward,
              child: Icon(Icons.replay_rounded, size: 18, color: iconColor),
            ),
            Text(
              '15',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: mutedColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seek bar — gradient wine→orange fill on a chip track (mockup 3a). Tap or
// drag anywhere on the track to seek; times sit below in tabular figures.
// ---------------------------------------------------------------------------

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.handler});
  final AudioPlayerHandler handler;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = dark
        ? Colors.white.withValues(alpha: 0.10)
        : AppColors.wine.withValues(alpha: 0.10);
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final timeStyle = TextStyle(
      color: mutedColor,
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return StreamBuilder<Duration>(
      stream: widget.handler.positionStream,
      builder: (_, posSnap) {
        final pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: widget.handler.durationStream,
          builder: (_, durSnap) {
            final dur = durSnap.data;
            final maxMs = (dur?.inMilliseconds ?? 0).toDouble();
            final curMs = _dragMs ??
                (maxMs == 0
                    ? 0.0
                    : pos.inMilliseconds
                        .clamp(0, maxMs.toInt())
                        .toDouble());
            final t = maxMs == 0 ? 0.0 : (curMs / maxMs).clamp(0.0, 1.0);

            return Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    double msFromDx(double dx) =>
                        maxMs == 0 ? 0 : (dx / w).clamp(0.0, 1.0) * maxMs;
                    void commit(double ms) {
                      widget.handler
                          .seek(Duration(milliseconds: ms.toInt()));
                      setState(() => _dragMs = null);
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: maxMs == 0
                          ? null
                          : (d) => commit(msFromDx(d.localPosition.dx)),
                      onHorizontalDragUpdate: maxMs == 0
                          ? null
                          : (d) => setState(
                              () => _dragMs = msFromDx(d.localPosition.dx)),
                      onHorizontalDragEnd: maxMs == 0
                          ? null
                          : (_) {
                              if (_dragMs != null) commit(_dragMs!);
                            },
                      child: SizedBox(
                        height: 24,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              height: 6,
                              width: double.infinity,
                              color: trackColor,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: t,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(999)),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.wine,
                                          AppColors.orange,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(Duration(milliseconds: curMs.toInt())),
                      style: timeStyle,
                    ),
                    StreamBuilder<PlayerState>(
                      stream: widget.handler.playerStateStream,
                      builder: (_, s) {
                        final loading = s.data?.processingState ==
                                ProcessingState.loading ||
                            s.data?.processingState ==
                                ProcessingState.buffering;
                        if (loading) {
                          return SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: mutedColor,
                            ),
                          );
                        }
                        return Text(
                          dur == null ? '--:--' : _fmt(dur),
                          style: timeStyle,
                        );
                      },
                    ),
                  ],
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
// Page list row (mockup 3a chapter list)
// ---------------------------------------------------------------------------

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.index,
    required this.page,
    required this.active,
    required this.isLast,
    required this.onTap,
  });
  final int index;
  final AudiobookPage page;
  final bool active;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final lineColor = dark ? AppColors.lineDark : AppColors.line;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? (dark
                            ? AppColors.wine300.withValues(alpha: 0.16)
                            : AppColors.wine100)
                        : (dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppColors.wine.withValues(alpha: 0.06)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${page.pageNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: active ? accent : mutedColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Bet ${page.pageNumber}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? textColor : mutedColor,
                    ),
                  ),
                ),
                if (active)
                  Icon(Icons.graphic_eq_rounded, size: 18, color: accent)
                else
                  Icon(Icons.play_arrow_rounded, size: 18, color: mutedColor),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 0.5, color: lineColor),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.wine, AppColors.wineDeep],
          ),
        ),
        child: const Center(
          child: Icon(Icons.menu_book_rounded,
              color: Colors.white30, size: 72),
        ),
      );
}

// ---------------------------------------------------------------------------
// Matn bottom sheet — frosted GlassSheet body
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final lineColor = dark ? AppColors.lineDark : AppColors.line;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => GlassSheet(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.wine300.withValues(alpha: 0.16)
                          : AppColors.wine100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bet $page',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.5, color: lineColor),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 18),
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16.5,
                      height: 1.9,
                      color: dark
                          ? AppColors.inkDarkPrimary.withValues(alpha: 0.9)
                          : AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 24),
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
// Locked gate — glass card + gradient CTA over ambient orbs
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final hasPending = access?.hasPendingOrder ?? false;
    final priceLabel = l.sumPrice(book.price.toStringAsFixed(0));

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassEntrance(
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.wine.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.wine.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.lock_rounded,
                            size: 40, color: AppColors.wine),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceLabel,
                        style: TextStyle(
                          color: dark ? AppColors.wine300 : AppColors.wine,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasPending
                            ? l.audiobookOrderPending
                            : l.buyAudiobookPrompt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: GlassPressable(
                          onTap: hasPending ? null : onBuy,
                          child: Opacity(
                            opacity: hasPending ? 0.5 : 1,
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppColors.wineGradient,
                                borderRadius: BorderRadius.circular(
                                    AppColors.radiusButton),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.wine
                                        .withValues(alpha: 0.30),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Text(
                                hasPending ? l.orderPending : l.buy,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onBack,
                        child: Text(
                          l.back,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _GlassCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),
        ],
      ),
    );
  }
}
