import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account_model.dart';

abstract class AccountLocalDataSource {
  Future<UserAccountModel?> getSavedAccount();
  Future<void> saveAccount(UserAccountModel account);
  Future<void> clearAccount();
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
  Future<List<UserAddressModel>> getSavedAddresses();
  Future<void> saveAddresses(List<UserAddressModel> addresses);
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  static const String _keyAccount = 'satset_user_account_data';
  static const String _keyNotifications = 'satset_account_notifications';
  static const String _keyAddresses = 'satset_user_addresses_data';

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
    await prefs.remove(_keyAddresses);
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

  @override
  Future<List<UserAddressModel>> getSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAddresses);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final rawList = jsonDecode(jsonStr) as List<dynamic>;
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((m) => UserAddressModel.fromJson(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveAddresses(List<UserAddressModel> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(addresses.map((a) => a.toJson()).toList());
    await prefs.setString(_keyAddresses, jsonStr);
  }
}
