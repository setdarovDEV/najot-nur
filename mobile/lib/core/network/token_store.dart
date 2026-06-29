import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_language.dart';
import '../constants/app_constants.dart';

/// Thin wrapper over SharedPreferences for auth tokens & flags.
class TokenStore {
  TokenStore(this._prefs);
  final SharedPreferences _prefs;

  String? get accessToken => _prefs.getString(AppConstants.kAccessToken);
  String? get refreshToken => _prefs.getString(AppConstants.kRefreshToken);
  bool get isLoggedIn => accessToken != null;
  bool get onboardingSeen =>
      _prefs.getBool(AppConstants.kOnboardingSeen) ?? false;
  AppLanguage get language => AppLanguage.fromCode(
        _prefs.getString(AppConstants.kLanguage),
      );

  Future<void> saveTokens(String access, String refresh) async {
    await _prefs.setString(AppConstants.kAccessToken, access);
    await _prefs.setString(AppConstants.kRefreshToken, refresh);
  }

  Future<void> setLanguage(AppLanguage language) =>
      _prefs.setString(AppConstants.kLanguage, language.code);

  Future<void> clear() async {
    await _prefs.remove(AppConstants.kAccessToken);
    await _prefs.remove(AppConstants.kRefreshToken);
  }

  Future<void> setOnboardingSeen() =>
      _prefs.setBool(AppConstants.kOnboardingSeen, true);
}
