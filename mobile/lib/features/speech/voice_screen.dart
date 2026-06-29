import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_colors.dart';
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
  PronunciationReference? _ref;
  String? _audioPath;
  bool _loading = false;

  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
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

    return Scaffold(
      appBar: AppBar(title: Text(l.voiceCheck)),
      body: refs.when(
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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(l.selectText,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: list.map((r) {
                  final sel = r.id == _ref?.id;
                  return ChoiceChip(
                    label: Text(r.title),
                    selected: sel,
                    onSelected: (_) => setState(() => _ref = r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.wine100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            color: AppColors.wine, size: 20),
                        const SizedBox(width: 8),
                        Text(l.readText,
                            style: const TextStyle(
                                color: AppColors.wine,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ref!.text,
                      style: const TextStyle(
                          fontSize: 18, height: 1.6, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              if (_ref?.referenceAudioUrl != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.wine.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.wine.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.headphones_rounded,
                          color: AppColors.wine, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.listenExpert,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _toggleExpertAudio,
                        icon: Icon(_isPlaying
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_rounded),
                        label: Text(_isPlaying ? l.stopAudio : l.playAudio),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.wine,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: RecordButton(
                  onStop: (path) => setState(() => _audioPath = path),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l.orDivider,
                        style: const TextStyle(color: AppColors.muted)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(l.uploadAudio),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              if (_audioPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.recordingReady,
                          style: const TextStyle(
                              color: AppColors.ink, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _analyze,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4))
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_loading ? l.analyzing : l.analyze),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
