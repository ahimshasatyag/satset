import '../entities/notification_item.dart';

abstract class NotificationRepository {
  /// Mengambil daftar notifikasi milik pengguna / kurir
  Future<List<NotificationItem>> getNotifications({
    int limit = 30,
    int offset = 0,
    NotificationFilter filter = NotificationFilter.all,
    String? searchQuery,
    bool isCourier = false,
    String? courierId,
    String? userId,
  });

  /// Mengambil jumlah notifikasi yang belum dibaca
  Future<int> getUnreadCount({
    bool isCourier = false,
    String? courierId,
    String? userId,
  });

  /// Menandai satu notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId, {bool isCourier = false});

  /// Menandai seluruh notifikasi sebagai sudah dibaca
  Future<void> markAllAsRead({
    bool isCourier = false,
    String? courierId,
    String? userId,
  });

  /// Menghapus satu notifikasi
  Future<void> deleteNotification(String notificationId, {bool isCourier = false});

  /// Menghapus seluruh riwayat notifikasi
  Future<void> clearAllNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
  });

  /// Membuat notifikasi baru dan menyimpannya langsung ke database Supabase
  Future<NotificationItem> createNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? shipmentId,
    bool isCourier = false,
    String? courierId,
    String? userId,
  });

  /// Berlangganan aliran notifikasi baru secara real-time via Supabase
  Stream<List<NotificationItem>> subscribeNotifications({
    bool isCourier = false,
    String? courierId,
    String? userId,
  });
}
