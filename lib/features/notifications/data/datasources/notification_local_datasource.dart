import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item_model.dart';

abstract class NotificationLocalDataSource {
  Future<List<NotificationItemModel>> getCachedNotifications();
  Future<void> cacheNotifications(List<NotificationItemModel> notifications);
  Future<void> markNotificationAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> clearCache();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  static const String _keyNotifications = 'satset_cached_notifications_data';
  final SharedPreferences? _prefs;

  NotificationLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<NotificationItemModel>> getCachedNotifications() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyNotifications);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => NotificationItemModel.fromJson(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheNotifications(
      List<NotificationItemModel> notifications) async {
    final prefs = await _getPrefs();
    final jsonStr =
        jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_keyNotifications, jsonStr);
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    final current = await getCachedNotifications();
    final updated = current.map((n) {
      if (n.id == notificationId) {
        return NotificationItemModel.fromEntity(
          n.copyWith(isRead: true, readAt: DateTime.now()),
        );
      }
      return n;
    }).toList();
    await cacheNotifications(updated);
  }

  @override
  Future<void> markAllAsRead() async {
    final current = await getCachedNotifications();
    final updated = current.map((n) {
      return NotificationItemModel.fromEntity(
        n.copyWith(isRead: true, readAt: DateTime.now()),
      );
    }).toList();
    await cacheNotifications(updated);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    final current = await getCachedNotifications();
    final updated = current.where((n) => n.id != notificationId).toList();
    await cacheNotifications(updated);
  }

  @override
  Future<void> clearCache() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyNotifications);
  }
}
