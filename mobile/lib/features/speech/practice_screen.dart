import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
  String _difficulty = 'easy';
  PracticeText? _practiceText;
  bool _generating = false;
  String? _audioPath;
  bool _analyzing = false;

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
          SnackBar(content: Text(AppLocalizations.of(context).errorPrefix(e.toString()))),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l.practiceSpeech),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.selectDifficulty,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _DifficultySelector(
              selected: _difficulty,
              onChanged: (d) => setState(() {
                _difficulty = d;
                _practiceText = null;
                _audioPath = null;
              }),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _generating ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wine,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              label: Text(
                _generating ? l.generatingText : l.generateText,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            if (_practiceText != null) ...[
              const SizedBox(height: 28),
              Text(
                l.practiceReadText,
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  _practiceText!.text,
                  style: const TextStyle(
                      fontSize: 17, height: 1.6, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
              RecordButton(
                onStop: (path) {
                  if (path != null) setState(() => _audioPath = path);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      AppLocalizations.of(context).orDivider,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(AppLocalizations.of(context).uploadAudio),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              if (_audioPath != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _analyzing ? null : _analyze,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _analyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.analytics_rounded, color: Colors.white),
                  label: Text(
                    _analyzing ? l.analyzing : l.finishAndAnalyze,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      ('easy', l.difficultyEasy, Icons.sentiment_satisfied_rounded, Colors.green),
      ('medium', l.difficultyMedium, Icons.sentiment_neutral_rounded, Colors.orange),
      ('hard', l.difficultyHard, Icons.sentiment_very_dissatisfied_rounded, Colors.red),
    ];
    return Row(
      children: items.map((item) {
        final (value, label, icon, color) = item;
        final isSelected = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : AppColors.line,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: isSelected ? color : AppColors.muted, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.muted,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
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
