import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';

/// In-app WebView that hosts the Telegram Login Widget and exchanges the
/// resulting payload for a backend JWT pair.
///
/// Flow (Telegram Login Widget — see https://core.telegram.org/widgets/login):
/// 1. We load `https://oauth.telegram.org/auth?bot_id=…&origin=…&embed=1`
///    inside an [InAppWebView] (so the user never leaves the app).
/// 2. After the user confirms, Telegram redirects the WebView to
///    `https://oauth.telegram.org/auth#data=<base64-urlencoded-payload>`.
/// 3. We intercept the redirect via the navigation hooks, parse the
///    payload, and forward it to `/auth/telegram` on our backend (which
///    verifies the HMAC signature against the bot token and issues a
///    JWT pair).
class TelegramLoginScreen extends ConsumerStatefulWidget {
  const TelegramLoginScreen({super.key});

  @override
  ConsumerState<TelegramLoginScreen> createState() =>
      _TelegramLoginScreenState();
}

class _TelegramLoginScreenState extends ConsumerState<TelegramLoginScreen> {
  bool _busy = false;
  String? _error;
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final configAsync = ref.watch(authConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.wine,
        elevation: 0,
        title: Text(
          l.telegramLogin,
          style: const TextStyle(
            color: AppColors.wine,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _busy ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                color: AppColors.danger.withValues(alpha: 0.08),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                  ),
                ),
              ),
            Expanded(
              child: configAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(authConfigProvider),
                ),
                data: (cfg) {
                  if (!cfg.telegramLoginEnabled) {
                    return _ErrorView(message: l.telegramNotConfigured);
                  }
                  return _buildWebView(cfg.telegramBotUsername);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView(String botUsername) {
    final l = AppLocalizations.of(context);
    // The Telegram Login Widget needs a registered `origin` (the domain
    // the bot owner approved in @BotFather). For development we default
    // to a placeholder; production apps should pass their real origin
    // via `--dart-define=TELEGRAM_OAUTH_ORIGIN=…`.
    const origin = String.fromEnvironment(
      'TELEGRAM_OAUTH_ORIGIN',
      defaultValue: 'https://notiqlik.uz',
    );
    final url = Uri.https('oauth.telegram.org', '/auth', {
      'bot_id': botUsername.replaceFirst('@', ''),
      'origin': origin,
      'embed': '1',
      'request_access': 'write',
      'lang': Localizations.localeOf(context).languageCode,
    });

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url.toString())),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            safeBrowsingEnabled: false,
          ),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            return _handleNavigation(navigationAction.request.url);
          },
          onLoadStop: (controller, loadedUrl) async {
            // Belt-and-braces: Telegram sometimes injects the payload
            // via a JS-only fragment change that doesn't trigger
            // shouldOverrideUrlLoading. We re-check the URL after every
            // page-load and pull the fragment ourselves.
            await _maybeExtractFromUrl(loadedUrl);
          },
          onReceivedError: (controller, request, error) {
            // Suppress noisy errors from third-party trackers that the
            // widget itself injects (mc.yandex, google-analytics, …).
            final desc = error.description ?? '';
            if (desc.contains('net::ERR_ABORTED') ||
                desc.contains('ERR_BLOCKED_BY_CLIENT')) {
              return;
            }
            developer.log(
              'WebView error: $desc',
              name: 'TelegramLogin',
            );
          },
        ),
        if (_busy)
          Container(
            color: Colors.white.withValues(alpha: 0.85),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.wine),
                const SizedBox(height: 12),
                Text(
                  l.telegramVerifying,
                  style: const TextStyle(color: AppColors.wine),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<NavigationActionPolicy?> _handleNavigation(WebUri? uri) async {
    if (uri == null || _handled) return null;
    if (uri.host != 'oauth.telegram.org' && uri.host != 'telegram.org') {
      return null;
    }
    return _maybeExtractFromUrl(uri);
  }

  /// Returns [NavigationActionPolicy.CANCEL] when the URL carries a
  /// Telegram auth payload (so we stop loading), or null to let the
  /// WebView continue.
  Future<NavigationActionPolicy?> _maybeExtractFromUrl(WebUri? uri) async {
    if (uri == null || _handled) return null;
    // Telegram posts the payload either as a query param (after the
    // 302 redirect) or, more reliably, in the URL fragment.
    final raw = uri.fragment.isNotEmpty ? uri.fragment : uri.query;
    if (raw.isEmpty) return null;

    final params = Uri.splitQueryString(raw);
    final tg = _parseTelegramData(params);
    if (tg == null) return null;

    _handled = true;
    unawaited(_exchange(tg));
    return NavigationActionPolicy.CANCEL;
  }

  /// Telegram returns its payload as a single base64 string under `data=`
  /// (older flow) OR as separate query params (newer flow). Handle both.
  Map<String, String>? _parseTelegramData(Map<String, String> params) {
    if (params.containsKey('id') && params.containsKey('hash')) {
      return params;
    }
    final encoded = params['data'];
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = utf8.decode(base64.decode(encoded));
      return Uri.splitQueryString(decoded);
    } catch (e) {
      developer.log(
        'Failed to decode Telegram payload: $e',
        name: 'TelegramLogin',
      );
      return null;
    }
  }

  Future<void> _exchange(Map<String, String> tg) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = int.parse(tg['id']!);
      final authDate = int.parse(tg['auth_date']!);
      final hash = tg['hash']!;

      final result = await ref.read(authRepositoryProvider).telegramLogin(
            id: id,
            firstName: tg['first_name'],
            lastName: tg['last_name'],
            username: tg['username'],
            photoUrl: tg['photo_url'],
            authDate: authDate,
            hash: hash,
          );
      if (!mounted) return;
      await ref
          .read(authControllerProvider.notifier)
          .onAuthenticated(result.access, result.refresh);
      if (!mounted) return;
      final pending = ref.read(pendingReturnPathProvider);
      if (pending != null) {
        ref.read(pendingReturnPathProvider.notifier).state = null;
        context.go(pending);
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l.telegramLoginFailed(e.toString());
      });
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
