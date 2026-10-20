import 'package:shared_preferences/shared_preferences.dart';

abstract class MainNavigationLocalDataSource {
  Future<int> getLastSelectedTab();
  Future<void> saveLastSelectedTab(int index);
}

class MainNavigationLocalDataSourceImpl
    implements MainNavigationLocalDataSource {
  static const String _keyLastTab = 'satset_last_nav_tab';

  @override
  Future<int> getLastSelectedTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastTab) ?? 0;
  }

  @override
  Future<void> saveLastSelectedTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastTab, index);
  }
}
