import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_user_model.dart';
import '../utils/admin_cookie_manager.dart';

abstract class AdminAuthLocalDataSource {
  Future<void> saveAdmin(AdminUserModel admin);
  Future<AdminUserModel?> getAdmin();
  Future<void> deleteAdmin();
  Future<void> saveRememberMe({required String email, required bool remember});
  Future<Map<String, dynamic>> getRememberMe();
}

class AdminAuthLocalDataSourceImpl implements AdminAuthLocalDataSource {
  final SharedPreferences? sharedPreferences;

  static const String _keyAdmin = 'KEY_ADMIN_AUTH_USER';
  static const String _keyAdminToken = 'KEY_ADMIN_AUTH_TOKEN';
  static const String _keyAdminRememberMe = 'KEY_ADMIN_REMEMBER_ME';
  static const String _keyAdminSavedEmail = 'KEY_ADMIN_SAVED_EMAIL';

  AdminAuthLocalDataSourceImpl({this.sharedPreferences});

  Future<SharedPreferences> _getPrefs() async {
    return sharedPreferences ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveAdmin(AdminUserModel admin) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyAdmin, jsonEncode(admin.toJson()));
      final activeToken = admin.token ??
          'satset_admin_session_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_keyAdminToken, activeToken);
      AdminCookieManager.setAuthTokenCookie(
        token: activeToken,
        email: admin.email,
        role: admin.role,
      );
    } catch (_) {}
  }

  @override
  Future<AdminUserModel?> getAdmin() async {
    try {
      // Jika cookie auth token tidak ada, otomatis hapus sesi lokal (auto-logout)
      if (!AdminCookieManager.hasAuthTokenCookie()) {
        await deleteAdmin();
        return null;
      }

      final prefs = await _getPrefs();
      final str = prefs.getString(_keyAdmin);
      if (str != null && str.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(str);
        final token =
            AdminCookieManager.getAuthTokenCookie() ?? prefs.getString(_keyAdminToken);
        return AdminUserModel.fromJson(data, token: token);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteAdmin() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyAdmin);
      await prefs.remove(_keyAdminToken);
      AdminCookieManager.clearAuthTokenCookie();
    } catch (_) {}
  }

  @override
  Future<void> saveRememberMe({required String email, required bool remember}) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_keyAdminRememberMe, remember);
      if (remember) {
        await prefs.setString(_keyAdminSavedEmail, email);
      } else {
        await prefs.remove(_keyAdminSavedEmail);
      }
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>> getRememberMe() async {
    try {
      final prefs = await _getPrefs();
      final remember = prefs.getBool(_keyAdminRememberMe) ?? false;
      final email = prefs.getString(_keyAdminSavedEmail);
      return {
        'rememberMe': remember,
        'email': email,
      };
    } catch (_) {
      return {
        'rememberMe': false,
        'email': null,
      };
    }
  }
}

