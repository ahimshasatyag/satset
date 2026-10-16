import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Kontrak Local Data Source untuk mengelola sesi login & preferensi pengguna
abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> deleteUser();
  Future<void> saveRememberMe(bool rememberMe);
  Future<bool> isRememberMe();
  Future<void> saveSavedEmail(String email);
  Future<String?> getSavedEmail();
  Future<String?> getToken();
}

/// Implementasi Local Data Source menggunakan [SharedPreferences]
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences? sharedPreferences;

  static const String keyUser = 'KEY_AUTH_USER';
  static const String keyToken = 'KEY_AUTH_TOKEN';
  static const String keyRememberMe = 'KEY_AUTH_REMEMBER_ME';
  static const String keySavedEmail = 'KEY_AUTH_SAVED_EMAIL';

  AuthLocalDataSourceImpl({this.sharedPreferences});

  Future<SharedPreferences> _getPrefs() async {
    return sharedPreferences ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(keyUser, user.toRawJson());
      if (user.token != null) {
        await prefs.setString(keyToken, user.token!);
      }
    } catch (_) {}
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final prefs = await _getPrefs();
      final userString = prefs.getString(keyUser);
      if (userString != null && userString.isNotEmpty) {
        return UserModel.fromRawJson(userString);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(keyUser);
      await prefs.remove(keyToken);
    } catch (_) {}
  }

  @override
  Future<void> saveRememberMe(bool rememberMe) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyRememberMe, rememberMe);
    } catch (_) {}
  }

  @override
  Future<bool> isRememberMe() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(keyRememberMe) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveSavedEmail(String email) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(keySavedEmail, email);
    } catch (_) {}
  }

  @override
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(keySavedEmail);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(keyToken);
    } catch (_) {
      return null;
    }
  }
}
