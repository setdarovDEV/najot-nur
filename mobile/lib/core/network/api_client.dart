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
        onError: (err, handler) {
          final status = err.response?.statusCode;
          // Only treat as "session expired" when the user *was* authenticated
          // — otherwise the 401 is just a normal auth failure (e.g. wrong OTP)
          // and we should let the caller show its own error.
          if (status == 401 && _tokens.accessToken != null) {
            _handleSessionExpired();
          }
          handler.next(err);
        },
      ),
    );
  }

  final TokenStore _tokens;
  final OnSessionExpired? _onSessionExpired;
  late final Dio dio;
  bool _sessionExpiredFired = false;

  void _handleSessionExpired() {
    if (_sessionExpiredFired) return;
    _sessionExpiredFired = true;
    // Fire-and-forget — clearing prefs doesn't need to block the redirect.
    // ignore: discarded_futures
    _tokens.clear();
    _onSessionExpired?.call();
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
