import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/app_language.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/brand.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key, this.fromContext});

  /// 'onboarding' → go to /home after selecting
  /// 'auth'       → go to /auth after selecting
  /// null         → pop back (e.g. from profile settings)
  final String? fromContext;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  AppLanguage? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(localeProvider.notifier).setLanguage(_selected!);
      if (!mounted) return;
      switch (widget.fromContext) {
        case 'onboarding':
          context.go('/home');
        case 'auth':
          context.pushReplacement('/auth');
        default:
          // Called from profile settings — just pop back
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const BrandBadge(size: 72, radius: 20),
              const Spacer(),
              Text(
                l.selectLanguage,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.wine,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l.languagePrompt,
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              _LanguageTile(
                language: AppLanguage.uzbek,
                selected: _selected == AppLanguage.uzbek,
                onTap: () => setState(() => _selected = AppLanguage.uzbek),
              ),
              const SizedBox(height: 12),
              _LanguageTile(
                language: AppLanguage.russian,
                selected: _selected == AppLanguage.russian,
                onTap: () => setState(() => _selected = AppLanguage.russian),
              ),
              const SizedBox(height: 12),
              _LanguageTile(
                language: AppLanguage.english,
                selected: _selected == AppLanguage.english,
                onTap: () => setState(() => _selected = AppLanguage.english),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (_selected == null || _saving) ? null : _continue,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.4),
                      )
                    : Text(l.continueAction),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Always show the language in its own native script as the title.
    final native = language.nativeLabel;
    // Show the name in the current UI language as subtitle (may differ from native).
    final sub = switch (language) {
      AppLanguage.uzbek => l.uzbekLang,
      AppLanguage.russian => l.russianLang,
      AppLanguage.english => l.englishLang,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.wine100 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.wine : AppColors.line,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.wine : AppColors.muted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    native,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.wine : AppColors.ink,
                    ),
                  ),
                  if (sub != native) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
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
