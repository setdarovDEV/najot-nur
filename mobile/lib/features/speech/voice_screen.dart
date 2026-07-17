import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/speech_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import 'widgets/record_button.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final _scrollOffset = ValueNotifier<double>(0);
  PronunciationReference? _ref;
  String? _audioPath;
  bool _loading = false;

  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _scrollOffset.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleExpertAudio() async {
    if (_ref?.referenceAudioUrl == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    final apiClient = ref.read(apiClientProvider);
    final url = apiClient.resolveMediaUrl(_ref!.referenceAudioUrl!);
    await _player.setUrl(url);
    setState(() => _isPlaying = true);
    await _player.play();
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _audioPath = result.files.single.path!);
    }
  }

  Future<void> _analyze() async {
    final l = AppLocalizations.of(context);
    if (_ref == null || _audioPath == null) return;

    setState(() => _loading = true);
    try {
      final result = await ref.read(speechRepositoryProvider).analyzeVoiceAudio(
            referenceText: _ref!.text,
            filePath: _audioPath!,
            referenceId: _ref!.id,
          );
      if (mounted) context.push('/speech/voice/result', extra: result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.errorPrefix(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final refs = ref.watch(referencesProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          refs.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(referencesProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return ErrorView(message: l.noReferences);
              }
              _ref ??= list.first;
              return NotificationListener<ScrollNotification>(
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
                              l.voiceCheck,
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
                    const SizedBox(height: 16),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep,
                      child: Text(
                        l.selectText,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep * 2,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: list.map((r) {
                          final sel = r.id == _ref?.id;
                          return _GlassChip(
                            label: r.title,
                            active: sel,
                            onTap: () => setState(() => _ref = r),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep * 3,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    color: accent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l.readText,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _ref!.text,
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.6,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_ref?.referenceAudioUrl != null) ...[
                      const SizedBox(height: 12),
                      GlassEntrance(
                        delay: GlassMotion.entranceStep * 4,
                        child: GlassContainer(
                          borderRadius: AppColors.radiusButton,
                          withShadow: false,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.headphones_rounded,
                                  color: accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l.listenExpert,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              GlassPressable(
                                onTap: _toggleExpertAudio,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: dark
                                        ? AppColors.wine300
                                            .withValues(alpha: 0.16)
                                        : AppColors.wine100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isPlaying
                                            ? Icons.stop_circle_rounded
                                            : Icons.play_circle_rounded,
                                        color: accent,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isPlaying
                                            ? l.stopAudio
                                            : l.playAudio,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep * 5,
                      child: Center(
                        child: RecordButton(
                          onStop: (path) =>
                              setState(() => _audioPath = path),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _OrDivider(label: l.orDivider),
                    const SizedBox(height: 16),
                    _GlassSecondaryButton(
                      icon: Icons.upload_file_rounded,
                      label: l.uploadAudio,
                      onTap: _pickAudioFile,
                    ),
                    const SizedBox(height: 16),
                    if (_audioPath != null) ...[
                      _ReadyRow(label: l.recordingReady),
                      const SizedBox(height: 16),
                      _PrimaryCta(
                        label: _loading ? l.analyzing : l.analyze,
                        icon: Icons.auto_awesome_rounded,
                        loading: _loading,
                        onTap: _loading ? null : _analyze,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(offset: _scrollOffset, title: l.voiceCheck),
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

/// Frosted selection chip — active state morphs to the wine gradient.
class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GlassMotion.pressOut,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? AppColors.wineGradient : null,
          color: active
              ? null
              : (dark ? AppColors.glassFillDark : AppColors.glassFillLight),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? Colors.transparent
                : (dark
                    ? AppColors.glassStrokeDark
                    : AppColors.glassStrokeLight),
            width: 0.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : mutedColor,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final hairline = dark ? AppColors.lineDark : AppColors.line;
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: TextStyle(color: mutedColor, fontSize: 12.5)),
        ),
        Expanded(child: Container(height: 0.5, color: hairline)),
      ],
    );
  }
}

/// Frosted full-width secondary action (upload).
class _GlassSecondaryButton extends StatelessWidget {
  const _GlassSecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: AppColors.radiusButton,
        withShadow: false,
        height: 52,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: textColor),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppColors.radiusSegment),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wine-gradient primary CTA (nasiya_checkout `_PrimaryCta` idiom).
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null && !loading ? 0.5 : 1,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.wineGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusButton),
            boxShadow: [
              BoxShadow(
                color: AppColors.wine.withValues(alpha: 0.30),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4),
                )
              else
                Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
