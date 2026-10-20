import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account_model.dart';

abstract class AccountLocalDataSource {
  Future<UserAccountModel?> getSavedAccount();
  Future<void> saveAccount(UserAccountModel account);
  Future<void> clearAccount();
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  static const String _keyAccount = 'satset_user_account_data';
  static const String _keyNotifications = 'satset_account_notifications';

  @override
  Future<UserAccountModel?> getSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAccount);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserAccountModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAccount(UserAccountModel account) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(account.toJson());
    await prefs.setString(_keyAccount, jsonStr);
  }

  @override
  Future<void> clearAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccount);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
  }
}
