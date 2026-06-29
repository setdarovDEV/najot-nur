import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/practicum_models.dart';
import '../../providers/providers.dart';
import 'practicum_card.dart';

class PracticumsTab extends ConsumerStatefulWidget {
  const PracticumsTab({super.key});

  @override
  ConsumerState<PracticumsTab> createState() => _PracticumsTabState();
}

class _PracticumsTabState extends ConsumerState<PracticumsTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final practicumsAsync = ref.watch(practicumsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(l: l),
            _FilterBar(selected: _filter, onChanged: (v) => setState(() => _filter = v)),
            Expanded(
              child: practicumsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(message: l.errorPrefix(e.toString())),
                data: (list) {
                  final filtered = _applyFilter(list);
                  if (filtered.isEmpty) return _EmptyState(l: l);
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => PracticumInlineCard(practicum: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Practicum> _applyFilter(List<Practicum> list) {
    // Only show approved practicums on mobile
    final approved = list.where((p) => p.status == 'approved').toList();
    return switch (_filter) {
      'free' => approved.where((p) => p.isFree).toList(),
      'paid' => approved.where((p) => !p.isFree).toList(),
      _ => approved,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.practicumsTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l.practicumsSubtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'Hammasi'),
      ('free', 'Bepul'),
      ('paid', 'Pullik'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isActive = selected == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilterChip(
                  label: Text(
                    f.$2,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  selected: isActive,
                  onSelected: (_) => onChanged(f.$1),
                  selectedColor: AppColors.wine,
                  backgroundColor: AppColors.surface,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isActive ? AppColors.wine : AppColors.line,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.wine.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headphones_outlined,
                size: 40,
                color: AppColors.wine,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.noPracticums,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}
