import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers/providers.dart';
import 'shared/widgets/security_capture_overlay.dart';
import 'shared/widgets/security_watermark.dart';
import 'shared/widgets/update_required_dialog.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _initPush();
    });
  }

  Future<void> _initPush() async {
    final push = ref.read(pushServiceProvider);
    push.onOrderStatusChanged = (status, courseId, audiobookId) {
      // Invalidate orders list so status badge updates everywhere.
      ref.invalidate(myOrdersProvider);
      // Invalidate course/audiobook progress — the user now has (or lost) access.
      ref.invalidate(courseProgressProvider);
      ref.invalidate(audiobookAccessProvider);
      if (courseId.isNotEmpty) {
        ref.invalidate(coursesProvider);
        ref.invalidate(courseDetailProvider(courseId));
      }
      if (audiobookId.isNotEmpty) {
        ref.invalidate(audiobooksProvider);
        ref.invalidate(audiobookDetailProvider(audiobookId));
      }
    };
    push.onNavigate = (route) {
      ref.read(goRouterProvider).go(route);
    };
    await push.init();
  }

  @override
  Widget build(BuildContext context) {
    // Surface a snackbar and update AuthController whenever the API client
    // reports a session expiry (401 on a previously-authenticated request).
    ref.listen<int>(authEventsProvider.select((e) => e.sessionExpiredCount),
        (prev, next) {
      if (next == _lastSessionExpiredSeen) return;
      _lastSessionExpiredSeen = next;
      // Sync AuthController state — tokens were already cleared by ApiClient.
      ref.read(authControllerProvider.notifier).logoutLocally();
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
          if (mounted) _initPush();
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
      // Wrap every route with the security watermark + capture overlay.
      // The watermark is only rendered when the user is authenticated and
      // the server has returned a watermark text; otherwise the wrapper
      // passes the child through unchanged. The update-required overlay
      // sits on top of both so a forced update can never be bypassed by
      // the user navigating around the app.
      builder: (context, child) {
        final body = child ?? const SizedBox.shrink();
        return SecurityWatermark(
          child: SecurityCaptureOverlay(
            child: UpdateRequiredDialog(child: body),
          ),
        );
      },
    );
  }
}
