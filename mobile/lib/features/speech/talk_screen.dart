import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import 'widgets/record_button.dart';

class TalkScreen extends ConsumerStatefulWidget {
  const TalkScreen({super.key});

  @override
  ConsumerState<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends ConsumerState<TalkScreen> {
  final _scrollOffset = ValueNotifier<double>(0);
  String? _audioPath;
  bool _loading = false;

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _audioPath = result.files.single.path!);
    }
  }

  Future<void> _analyze() async {
    final l = AppLocalizations.of(context);
    if (_audioPath == null) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(speechRepositoryProvider).freeTalkAudio(
            filePath: _audioPath!,
          );
      if (mounted) context.push('/speech/talk/result', extra: result);
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
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
                          l.speechAnalysis,
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
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.wineGradient,
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusCard),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wine.withValues(alpha: 0.30),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.taskLabel.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.selfIntroPrompt,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...AppConstants.selfIntroQuestions.map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    q,
                                    style: const TextStyle(
                                        color: Colors.white, height: 1.4),
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
                const SizedBox(height: 26),
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 2,
                  child: Center(
                    child: RecordButton(
                      onStop: (path) => setState(() => _audioPath = path),
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
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.speechAnalysis),
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
