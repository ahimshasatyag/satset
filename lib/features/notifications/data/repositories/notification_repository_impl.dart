import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_item_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<NotificationItem>> getNotifications({
    int limit = 30,
    int offset = 0,
    NotificationFilter filter = NotificationFilter.all,
    String? searchQuery,
  }) async {
    try {
      final remoteList = await remoteDataSource.getNotifications(
        limit: limit,
        offset: offset,
        filter: filter,
        searchQuery: searchQuery,
      );

      // Simpan ke cache lokal jika halaman pertama tanpa filter/query pencarian
      if (offset == 0 &&
          filter == NotificationFilter.all &&
          (searchQuery == null || searchQuery.isEmpty)) {
        await localDataSource.cacheNotifications(remoteList);
      }

      return remoteList;
    } catch (_) {
      // Fallback ke cache lokal jika terjadi gangguan koneksi
      final cachedList = await localDataSource.getCachedNotifications();
      var filtered = cachedList.map((m) => m as NotificationItem).toList();

      if (filter == NotificationFilter.unread) {
        filtered = filtered.where((n) => !n.isRead).toList();
      } else if (filter == NotificationFilter.shipment) {
        filtered = filtered.where((n) => n.isShipment).toList();
      } else if (filter == NotificationFilter.payment) {
        filtered = filtered.where((n) => n.isPayment).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        filtered = filtered
            .where((n) =>
                n.title.toLowerCase().contains(q) ||
                n.message.toLowerCase().contains(q))
            .toList();
      }

      return filtered;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await remoteDataSource.getUnreadCount();
    } catch (_) {
      final cached = await localDataSource.getCachedNotifications();
      return cached.where((n) => !n.isRead).length;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await localDataSource.markNotificationAsRead(notificationId);
    try {
      await remoteDataSource.markAsRead(notificationId);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    await localDataSource.markAllAsRead();
    try {
      await remoteDataSource.markAllAsRead();
    } catch (_) {}
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await localDataSource.deleteNotification(notificationId);
    try {
      await remoteDataSource.deleteNotification(notificationId);
    } catch (_) {}
  }

  @override
  Future<void> clearAllNotifications() async {
    await localDataSource.clearCache();
    try {
      await remoteDataSource.clearAllNotifications();
    } catch (_) {}
  }

  @override
  Stream<List<NotificationItem>> subscribeNotifications() {
    return remoteDataSource.subscribeNotifications().map(
          (models) => models.map((m) => m as NotificationItem).toList(),
        );
  }
}
