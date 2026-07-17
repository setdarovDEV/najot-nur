import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/quiz_models.dart';
import '../../providers/providers.dart';
import 'widgets/record_button.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final _scrollOffset = ValueNotifier<double>(0);
  String _difficulty = 'easy';
  PracticeText? _practiceText;
  bool _generating = false;
  String? _audioPath;
  bool _analyzing = false;

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _practiceText = null;
      _audioPath = null;
    });
    try {
      final result = await ref
          .read(practiceRepositoryProvider)
          .generateText(_difficulty);
      if (mounted) setState(() => _practiceText = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).errorPrefix(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _audioPath = result.files.single.path!);
    }
  }

  Future<void> _analyze() async {
    final l = AppLocalizations.of(context);
    if (_practiceText == null || _audioPath == null) return;
    setState(() => _analyzing = true);
    try {
      final result =
          await ref.read(speechRepositoryProvider).analyzeVoiceAudio(
                referenceText: _practiceText!.text,
                filePath: _audioPath!,
              );
      if (mounted) context.push('/speech/voice/result', extra: result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorPrefix(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

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
                          l.practiceSpeech,
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
                    l.selectDifficulty,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 2,
                  child: _DifficultySelector(
                    selected: _difficulty,
                    onChanged: (d) => setState(() {
                      _difficulty = d;
                      _practiceText = null;
                      _audioPath = null;
                    }),
                  ),
                ),
                const SizedBox(height: 18),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 3,
                  child: _PrimaryCta(
                    label: _generating ? l.generatingText : l.generateText,
                    icon: Icons.auto_awesome_rounded,
                    loading: _generating,
                    onTap: _generating ? null : _generate,
                  ),
                ),
                if (_practiceText != null) ...[
                  const SizedBox(height: 26),
                  Text(
                    l.practiceReadText,
                    style: TextStyle(
                      color: mutedColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassEntrance(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _practiceText!.text,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: RecordButton(
                      onStop: (path) {
                        if (path != null) setState(() => _audioPath = path);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OrDivider(label: l.orDivider),
                  const SizedBox(height: 14),
                  _GlassSecondaryButton(
                    icon: Icons.upload_file_rounded,
                    label: l.uploadAudio,
                    onTap: _pickAudioFile,
                  ),
                  if (_audioPath != null) ...[
                    const SizedBox(height: 16),
                    _PrimaryCta(
                      label: _analyzing ? l.analyzing : l.finishAndAnalyze,
                      icon: Icons.analytics_rounded,
                      loading: _analyzing,
                      onTap: _analyzing ? null : _analyze,
                    ),
                  ],
                ],
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.practiceSpeech),
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

/// Three frosted difficulty cards; the active one tints with its semantic
/// color and lifts on a wine-tinted shadow.
class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final items = [
      ('easy', l.difficultyEasy, Icons.sentiment_satisfied_rounded,
          AppColors.success),
      ('medium', l.difficultyMedium, Icons.sentiment_neutral_rounded,
          AppColors.warning),
      ('hard', l.difficultyHard, Icons.sentiment_very_dissatisfied_rounded,
          AppColors.danger),
    ];
    return Row(
      children: items.map((item) {
        final (value, label, icon, color) = item;
        final isSelected = selected == value;
        return Expanded(
          child: GlassPressable(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: GlassMotion.pressOut,
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: dark ? 0.20 : 0.12)
                    : (dark
                        ? AppColors.glassFillDark
                        : AppColors.glassFillLight),
                borderRadius:
                    BorderRadius.circular(AppColors.radiusSegment),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (dark
                          ? AppColors.glassStrokeDark
                          : AppColors.glassStrokeLight),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: isSelected ? color : mutedColor, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : mutedColor,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
