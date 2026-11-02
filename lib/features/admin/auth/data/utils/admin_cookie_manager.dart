import 'dart:async';
import 'admin_cookie_manager_stub.dart'
    if (dart.library.js_interop) 'admin_cookie_manager_web.dart' as cookie_impl;

class AdminCookieManager {
  static const String tokenCookieName = 'satset_admin_auth_token';
  static const String emailCookieName = 'satset_admin_email';
  static const String roleCookieName = 'satset_admin_role';

  /// Menyimpan auth token ke dalam browser cookies
  static void setAuthTokenCookie({
    required String token,
    required String email,
    String role = 'admin',
    int maxAgeSeconds = 86400,
  }) {
    cookie_impl.setAuthTokenCookieImpl(
      token: token,
      email: email,
      role: role,
      maxAgeSeconds: maxAgeSeconds,
    );
  }

  /// Membaca semua cookies terkait admin sebagai Map
  static Map<String, String> getAllCookies() {
    return cookie_impl.getAllCookiesImpl();
  }

  /// Membaca nilai auth token dari cookies
  static String? getAuthTokenCookie() {
    return cookie_impl.getAuthTokenCookieImpl();
  }

  /// Memeriksa apakah cookie auth token masih tersedia dan valid
  static bool hasAuthTokenCookie() {
    final token = getAuthTokenCookie();
    return token != null && token.trim().isNotEmpty;
  }

  /// Menghapus auth token cookies saat logout
  static void clearAuthTokenCookie() {
    cookie_impl.clearAuthTokenCookieImpl();
  }

  /// Memantau keberadaan cookie auth token secara berkala.
  /// Jika cookie auth token tidak ada / dihapus dari browser, otomatis memicu [onCookieMissing].
  static Timer startCookieWatcher({
    required void Function() onCookieMissing,
    Duration interval = const Duration(seconds: 1),
  }) {
    return Timer.periodic(interval, (timer) {
      if (!hasAuthTokenCookie()) {
        timer.cancel();
        onCookieMissing();
      }
    });
  }

  /// Mendaftarkan fungsi global `window.setAdminAuthToken(token, email)` di Browser Console
  static void registerConsoleTokenHelper({
    required void Function(String token, String email) onTokenLogin,
  }) {
    cookie_impl.registerConsoleTokenHelperImpl(onTokenLogin: onTokenLogin);
  }
}
