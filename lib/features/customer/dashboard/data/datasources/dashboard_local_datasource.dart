import 'package:shared_preferences/shared_preferences.dart';

abstract class DashboardLocalDataSource {
  Future<List<String>> getSearchHistory();
  Future<void> addSearchHistory(String trackingNumber);
  Future<void> clearSearchHistory();
  Future<bool> hasUnreadNotifications();
  Future<void> setNotificationsRead(bool isRead);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  static const String _keySearchHistory = 'satset_tracking_history';
  static const String _keyNotificationsRead = 'satset_notifications_read';

  final SharedPreferences? sharedPreferences;

  DashboardLocalDataSourceImpl({this.sharedPreferences});

  Future<SharedPreferences> _getPrefs() async {
    return sharedPreferences ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<String>> getSearchHistory() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_keySearchHistory) ?? const [];
  }

  @override
  Future<void> addSearchHistory(String trackingNumber) async {
    final clean = trackingNumber.trim().toUpperCase();
    if (clean.isEmpty) return;

    final prefs = await _getPrefs();
    final list = List<String>.from(prefs.getStringList(_keySearchHistory) ?? const []);
    list.remove(clean);
    list.insert(0, clean);
    if (list.length > 5) {
      list.removeRange(5, list.length);
    }
    await prefs.setStringList(_keySearchHistory, list);
  }

  @override
  Future<void> clearSearchHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keySearchHistory);
  }

  @override
  Future<bool> hasUnreadNotifications() async {
    final prefs = await _getPrefs();
    final isRead = prefs.getBool(_keyNotificationsRead) ?? false;
    return !isRead;
  }

  @override
  Future<void> setNotificationsRead(bool isRead) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyNotificationsRead, isRead);
  }
}
