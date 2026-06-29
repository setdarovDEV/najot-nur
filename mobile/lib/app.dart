import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers/providers.dart';

class NotiqAiApp extends ConsumerStatefulWidget {
  const NotiqAiApp({super.key});

  @override
  ConsumerState<NotiqAiApp> createState() => _NotiqAiAppState();
}

class _NotiqAiAppState extends ConsumerState<NotiqAiApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  int _lastSessionExpiredSeen = 0;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pushServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Surface a snackbar whenever the API client reports a session expiry.
    ref.listen<int>(authEventsProvider.select((e) => e.sessionExpiredCount),
        (prev, next) {
      if (next == _lastSessionExpiredSeen) return;
      _lastSessionExpiredSeen = next;
      final l = AppLocalizations.of(context);
      _scaffoldMessengerKey.currentState
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(l.sessionExpired),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
    });

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.isLoggedIn && !_wasLoggedIn) {
        _wasLoggedIn = true;
        Future.microtask(() {
          if (mounted) ref.read(pushServiceProvider).init();
        });
      } else if (!next.isLoggedIn) {
        _wasLoggedIn = false;
      }
    });

    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'NotiqAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
