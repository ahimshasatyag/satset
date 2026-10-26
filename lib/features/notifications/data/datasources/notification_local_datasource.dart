import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item_model.dart';

abstract class NotificationLocalDataSource {
  Future<List<NotificationItemModel>> getCachedNotifications({bool isCourier = false});
  Future<void> cacheNotifications(List<NotificationItemModel> notifications, {bool isCourier = false});
  Future<void> markNotificationAsRead(String notificationId, {bool isCourier = false});
  Future<void> markAllAsRead({bool isCourier = false});
  Future<void> deleteNotification(String notificationId, {bool isCourier = false});
  Future<void> clearCache({bool isCourier = false});
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  static const String _keyNotifications = 'satset_cached_notifications_data';
  static const String _keyCourierNotifications = 'satset_cached_courier_notifications_data';
  final SharedPreferences? prefs;

  NotificationLocalDataSourceImpl({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  String _resolveKey(bool isCourier) => isCourier ? _keyCourierNotifications : _keyNotifications;

  @override
  Future<List<NotificationItemModel>> getCachedNotifications({bool isCourier = false}) async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_resolveKey(isCourier));
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
    List<NotificationItemModel> notifications, {
    bool isCourier = false,
  }) async {
    final prefs = await _getPrefs();
    final jsonStr =
        jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_resolveKey(isCourier), jsonStr);
  }

  @override
  Future<void> markNotificationAsRead(String notificationId, {bool isCourier = false}) async {
    final current = await getCachedNotifications(isCourier: isCourier);
    final updated = current.map((n) {
      if (n.id == notificationId) {
        return NotificationItemModel.fromEntity(
          n.copyWith(isRead: true, readAt: DateTime.now()),
        );
      }
      return n;
    }).toList();
    await cacheNotifications(updated, isCourier: isCourier);
  }

  @override
  Future<void> markAllAsRead({bool isCourier = false}) async {
    final current = await getCachedNotifications(isCourier: isCourier);
    final updated = current.map((n) {
      return NotificationItemModel.fromEntity(
        n.copyWith(isRead: true, readAt: DateTime.now()),
      );
    }).toList();
    await cacheNotifications(updated, isCourier: isCourier);
  }

  @override
  Future<void> deleteNotification(String notificationId, {bool isCourier = false}) async {
    final current = await getCachedNotifications(isCourier: isCourier);
    final updated = current.where((n) => n.id != notificationId).toList();
    await cacheNotifications(updated, isCourier: isCourier);
  }

  @override
  Future<void> clearCache({bool isCourier = false}) async {
    final prefs = await _getPrefs();
    await prefs.remove(_resolveKey(isCourier));
  }
}
