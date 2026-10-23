import 'package:shared_preferences/shared_preferences.dart';

abstract class MainNavigationLocalDataSource {
  Future<int> getLastSelectedTab();
  Future<void> saveLastSelectedTab(int index);

  /// Mengambil index tab navigasi kurir yang terakhir dibuka
  Future<int> getCourierLastSelectedTab();

  /// Menyimpan index tab navigasi kurir yang terakhir dibuka
  Future<void> saveCourierLastSelectedTab(int index);

  /// Mengambil cache otorisasi akun kurir
  Future<bool?> getCachedCourierAuthorization(String courierId);

  /// Menyimpan status otorisasi akun kurir
  Future<void> cacheCourierAuthorization(String courierId, bool isAuthorized);

  /// Menghapus sesi lokal kurir saat keluar (logout)
  Future<void> clearCourierSession();
}

class MainNavigationLocalDataSourceImpl
    implements MainNavigationLocalDataSource {
  static const String _keyLastTab = 'satset_last_nav_tab';
  static const String _keyCourierLastTab = 'satset_courier_last_nav_tab';
  static const String _keyCourierAuthPrefix = 'satset_courier_auth_cache_';

  final SharedPreferences? _prefsInstance;

  MainNavigationLocalDataSourceImpl({SharedPreferences? sharedPreferences})
      : _prefsInstance = sharedPreferences;

  Future<SharedPreferences> _getPrefs() async {
    return _prefsInstance ?? await SharedPreferences.getInstance();
  }

  @override
  Future<int> getLastSelectedTab() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyLastTab) ?? 0;
  }

  @override
  Future<void> saveLastSelectedTab(int index) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyLastTab, index);
  }

  @override
  Future<int> getCourierLastSelectedTab() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyCourierLastTab) ?? 0;
  }

  @override
  Future<void> saveCourierLastSelectedTab(int index) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyCourierLastTab, index);
  }

  @override
  Future<bool?> getCachedCourierAuthorization(String courierId) async {
    if (courierId.isEmpty) return null;
    final prefs = await _getPrefs();
    return prefs.getBool('$_keyCourierAuthPrefix$courierId');
  }

  @override
  Future<void> cacheCourierAuthorization(
      String courierId, bool isAuthorized) async {
    if (courierId.isEmpty) return;
    final prefs = await _getPrefs();
    await prefs.setBool('$_keyCourierAuthPrefix$courierId', isAuthorized);
  }

  @override
  Future<void> clearCourierSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCourierLastTab);
  }
}
