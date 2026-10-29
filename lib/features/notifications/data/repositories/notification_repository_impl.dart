import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';

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
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    try {
      final remoteList = await remoteDataSource.getNotifications(
        limit: limit,
        offset: offset,
        filter: filter,
        searchQuery: searchQuery,
        isCourier: isCourier,
        courierId: courierId,
        userId: userId,
      );

      // Simpan ke cache lokal jika halaman pertama tanpa filter/query pencarian
      if (offset == 0 &&
          filter == NotificationFilter.all &&
          (searchQuery == null || searchQuery.isEmpty)) {
        await localDataSource.cacheNotifications(remoteList, isCourier: isCourier);
      }

      return remoteList;
    } catch (_) {
      // Fallback ke cache lokal jika terjadi gangguan koneksi
      final cachedList = await localDataSource.getCachedNotifications(isCourier: isCourier);
      var filtered = cachedList.map((m) => m as NotificationItem).toList();

      if (filter == NotificationFilter.unread) {
        filtered = filtered.where((n) => !n.isRead).toList();
      } else if (filter == NotificationFilter.shipment) {
        filtered = filtered.where((n) => n.isShipment).toList();
      } else if (filter == NotificationFilter.payment) {
        filtered = filtered.where((n) => n.isPayment).toList();
      } else if (filter == NotificationFilter.assignment) {
        filtered = filtered.where((n) => n.isAssignment).toList();
      } else if (filter == NotificationFilter.urgent) {
        filtered = filtered.where((n) => n.isUrgent).toList();
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
  Future<int> getUnreadCount({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    try {
      return await remoteDataSource.getUnreadCount(
        isCourier: isCourier,
        courierId: courierId,
        userId: userId,
      );
    } catch (_) {
      final cached = await localDataSource.getCachedNotifications(isCourier: isCourier);
      return cached.where((n) => !n.isRead).length;
    }
  }

  @override
  Future<void> markAsRead(String notificationId, {bool isCourier = false}) async {
    await localDataSource.markNotificationAsRead(notificationId, isCourier: isCourier);
    try {
      await remoteDataSource.markAsRead(notificationId);
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    await localDataSource.markAllAsRead(isCourier: isCourier);
    try {
      await remoteDataSource.markAllAsRead(
        isCourier: isCourier,
        courierId: courierId,
        userId: userId,
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteNotification(String notificationId, {bool isCourier = false}) async {
    await localDataSource.deleteNotification(notificationId, isCourier: isCourier);
    try {
      await remoteDataSource.deleteNotification(notificationId);
    } catch (_) {}
  }

  @override
  Future<void> clearAllNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    await localDataSource.clearCache(isCourier: isCourier);
    try {
      await remoteDataSource.clearAllNotifications(
        isCourier: isCourier,
        courierId: courierId,
        userId: userId,
      );
    } catch (_) {}
  }

  @override
  Future<NotificationItem> createNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? shipmentId,
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) async {
    final created = await remoteDataSource.createNotification(
      title: title,
      message: message,
      type: type,
      shipmentId: shipmentId,
      isCourier: isCourier,
      courierId: courierId,
      userId: userId,
    );

    try {
      final current = await localDataSource.getCachedNotifications(isCourier: isCourier);
      await localDataSource.cacheNotifications([created, ...current], isCourier: isCourier);
    } catch (_) {}

    return created;
  }

  @override
  Stream<List<NotificationItem>> subscribeNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
  }) {
    return remoteDataSource
        .subscribeNotifications(
          isCourier: isCourier,
          courierId: courierId,
          userId: userId,
        )
        .map((models) => models.map((m) => m as NotificationItem).toList());
  }
}
