import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final faqs = [
      (q: l.faq1Q, a: l.faq1A),
      (q: l.faq2Q, a: l.faq2A),
      (q: l.faq3Q, a: l.faq3A),
      (q: l.faq4Q, a: l.faq4A),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.faqTitle), titleSpacing: 20),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) =>
            _FaqTile(question: faqs[i].q, answer: faqs[i].a),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _open ? AppColors.wine.withValues(alpha: 0.3) : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              widget.question,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _open ? AppColors.wine : AppColors.ink,
              ),
            ),
            trailing: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted),
            ),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
