import 'package:shared_preferences/shared_preferences.dart';

abstract class DashboardLocalDataSource {
  Future<List<String>> getSearchHistory();
  Future<void> addSearchHistory(String trackingNumber);
  Future<bool> hasUnreadNotifications();
  Future<void> setNotificationsRead(bool isRead);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  static const String _keySearchHistory = 'satset_tracking_history';
  static const String _keyNotificationsRead = 'satset_notifications_read';

  @override
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySearchHistory) ??
        ['SS-98214-ID', 'SS-76219-ID'];
  }

  @override
  Future<void> addSearchHistory(String trackingNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySearchHistory) ?? [];
    if (!list.contains(trackingNumber)) {
      list.insert(0, trackingNumber);
      if (list.length > 5) {
        list.removeLast();
      }
      await prefs.setStringList(_keySearchHistory, list);
    }
  }

  @override
  Future<bool> hasUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final isRead = prefs.getBool(_keyNotificationsRead) ?? false;
    return !isRead;
  }

  @override
  Future<void> setNotificationsRead(bool isRead) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsRead, isRead);
  }
}
