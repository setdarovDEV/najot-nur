import 'package:flutter/foundation.dart';

/// Notifier for cross-cutting auth events (currently just "session expired").
///
/// * The Dio interceptor calls [notifySessionExpired] when the backend returns
///   a 401 — tokens have already been cleared by then.
/// * The GoRouter listens via [refreshListenable] so the user is bounced to
///   the login screen immediately.
/// * The app shell can `ref.listen` on the provider to surface a snackbar.
class AuthEvents extends ChangeNotifier {
  int _sessionExpiredCount = 0;
  int get sessionExpiredCount => _sessionExpiredCount;

  void notifySessionExpired() {
    _sessionExpiredCount++;
    notifyListeners();
  }
}
