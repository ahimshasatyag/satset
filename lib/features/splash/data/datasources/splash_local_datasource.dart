import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';

/// Kontrak Local Data Source untuk membaca status login & konfigurasi splash
abstract class SplashLocalDataSource {
  Future<AppSettingsModel> getAppSettings();
  Future<bool> checkAuthStatus();
  Future<void> setFirstTime(bool isFirstTime);
  Future<void> setAuthStatus(bool isAuthenticated);
}

/// Implementasi Local Data Source menggunakan [SharedPreferences]
class SplashLocalDataSourceImpl implements SplashLocalDataSource {
  final SharedPreferences? sharedPreferences;

  static const String keyIsAuthenticated = 'KEY_IS_AUTHENTICATED';
  static const String keyIsFirstTime = 'KEY_IS_FIRST_TIME';
  static const String keyAppVersion = 'KEY_APP_VERSION';
  static const String keyAppName = 'KEY_APP_NAME';

  SplashLocalDataSourceImpl({this.sharedPreferences});

  Future<SharedPreferences> _getPrefs() async {
    return sharedPreferences ?? await SharedPreferences.getInstance();
  }

  @override
  Future<AppSettingsModel> getAppSettings() async {
    try {
      final prefs = await _getPrefs();
      final isAuth = prefs.getBool(keyIsAuthenticated) ?? false;
      final isFirstTime = prefs.getBool(keyIsFirstTime) ?? true;
      final version = prefs.getString(keyAppVersion) ?? '1.0.0';
      final name = prefs.getString(keyAppName) ?? 'SatSet Express';

      return AppSettingsModel(
        isAuthenticated: isAuth,
        isFirstTime: isFirstTime,
        appVersion: version,
        appName: name,
      );
    } catch (_) {
      // Fallback aman jika penyimpanan lokal sedang tidak dapat diakses
      return const AppSettingsModel(
        isAuthenticated: false,
        isFirstTime: true,
        appVersion: '1.0.0',
        appName: 'SatSet Express',
      );
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(keyIsAuthenticated) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setFirstTime(bool isFirstTime) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyIsFirstTime, isFirstTime);
    } catch (_) {
      // Ignore write errors on fallback
    }
  }

  @override
  Future<void> setAuthStatus(bool isAuthenticated) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyIsAuthenticated, isAuthenticated);
    } catch (_) {
      // Ignore write errors on fallback
    }
  }
}
