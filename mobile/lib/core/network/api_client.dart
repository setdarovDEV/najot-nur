import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'token_store.dart';

/// Exception carrying a user-friendly message parsed from the API error body.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// Callback fired once when the backend rejects the current access token.
/// Implementations should clear local credentials and route the user back to
/// the login screen. Subsequent 401s are coalesced until the user logs in
/// again (avoids a flood of redirects).
typedef OnSessionExpired = void Function();

/// Configured Dio client. Attaches the bearer token, normalizes errors, and
/// surfaces session-expired events to the app shell.
class ApiClient {
  ApiClient(this._tokens, {OnSessionExpired? onSessionExpired})
      : _onSessionExpired = onSessionExpired {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          final status = err.response?.statusCode;
          // Only treat as "session expired" when the user *was* authenticated
          // — otherwise the 401 is just a normal auth failure (e.g. wrong OTP)
          // and we should let the caller show its own error.
          if (status == 401 && _tokens.accessToken != null) {
            final alreadyRetried =
                err.requestOptions.extra['_authRetried'] == true;
            if (!alreadyRetried) {
              err.requestOptions.extra['_authRetried'] = true;
              if (await _refreshAccessToken()) {
                try {
                  // onRequest re-attaches the Authorization header from
                  // TokenStore, which _refreshAccessToken() just updated.
                  final response = await dio.fetch(err.requestOptions);
                  return handler.resolve(response);
                } catch (_) {
                  // Fall through to session-expired below.
                }
              }
            }
            _handleSessionExpired();
          }
          handler.next(err);
        },
      ),
    );
    // Added after a deploy-time incident: right as the backend container
    // restarts, nginx can hold a stale upstream IP for a couple seconds and
    // return 502/503/504 (or a bare connection error) to whoever calls in
    // that window — most visibly on login. One transparent retry papers
    // over that gap without the user ever seeing an error. Interceptors'
    // onError runs in reverse-add order, so this retry fires before the
    // session-expired check above.
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) async {
          final alreadyRetried = err.requestOptions.extra['_retried'] == true;
          if (!alreadyRetried && _isTransient(err)) {
            err.requestOptions.extra['_retried'] = true;
            await Future.delayed(const Duration(milliseconds: 800));
            try {
              final response = await dio.fetch(err.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              // Fall through to the normal error path below.
            }
          }
          handler.next(err);
        },
      ),
    );
  }

  static bool _isTransient(DioException err) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    final status = err.response?.statusCode;
    return status == 502 || status == 503 || status == 504;
  }

  final TokenStore _tokens;
  final OnSessionExpired? _onSessionExpired;
  late final Dio dio;
  bool _sessionExpiredFired = false;
  Future<bool>? _refreshingFuture;

  void _handleSessionExpired() {
    if (_sessionExpiredFired) return;
    _sessionExpiredFired = true;
    // Fire-and-forget — clearing prefs doesn't need to block the redirect.
    // ignore: discarded_futures
    _tokens.clear();
    _onSessionExpired?.call();
  }

  /// Exchanges the stored refresh token for a fresh access+refresh pair and
  /// persists both. The backend rotates refresh tokens on every call — if
  /// several requests 401 at once, they must all await the same in-flight
  /// refresh instead of each calling /auth/refresh, since a second call
  /// would reuse an already-rotated (and now blacklisted) token.
  ///
  /// Uses a bare Dio instance (no interceptors) so a failed refresh can't
  /// recursively trigger this same error handler.
  Future<bool> _refreshAccessToken() {
    return _refreshingFuture ??= () async {
      final refreshToken = _tokens.refreshToken;
      if (refreshToken == null) return false;
      try {
        final plainDio = Dio(BaseOptions(baseUrl: AppConstants.apiUrl));
        final response = await plainDio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        await _tokens.saveTokens(
          response.data['access_token'] as String,
          response.data['refresh_token'] as String,
        );
        return true;
      } catch (_) {
        return false;
      } finally {
        _refreshingFuture = null;
      }
    }();
  }

  /// Call after a successful login so a future 401 can fire again.
  void resetSessionExpiredFlag() {
    _sessionExpiredFired = false;
  }

  /// Build a full URL for a media path returned by the API.
  ///
  /// The API returns paths like `/media/audiobooks/main_xxx.mp3`. We combine
  /// them with the API host, stripping the `/api/v1` suffix if present, so the
  /// resulting URL points at the backend's static `/media` mount.
  String resolveMediaUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AppConstants.apiUrl.endsWith('/')
        ? AppConstants.apiUrl.substring(0, AppConstants.apiUrl.length - 1)
        : AppConstants.apiUrl;
    final host = base.endsWith('/api/v1')
        ? base.substring(0, base.length - '/api/v1'.length)
        : base;
    final tail = path.startsWith('/') ? path : '/$path';
    return '$host$tail';
  }

  /// Maps Dio/network failures to [ApiException] with the server message.
  ApiException toApiException(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        return ApiException(
          (data['error']['message'] as String?) ?? 'Xatolik yuz berdi',
          statusCode: error.response?.statusCode,
          code: data['error']['code'] as String?,
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return ApiException('Internet aloqasi yo\'q yoki server ishlamayapti.');
      }
      return ApiException(
        error.message ?? 'Server xatosi',
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException('Kutilmagan xatolik: $error');
  }
}
