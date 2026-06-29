import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/brand.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.wine),
                ),
              ),
              const Spacer(),
              const Center(child: BrandBadge(size: 96, radius: 26)),
              const SizedBox(height: 28),
              Text(
                l.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.push('/auth/phone'),
                icon: const Icon(Icons.phone_iphone_rounded),
                label: Text(l.phoneLogin),
              ),
              const SizedBox(height: 16),
              Text(
                l.termsNotice,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
