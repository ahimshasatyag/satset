import '../entities/notification_item.dart';

abstract class NotificationRepository {
  /// Mengambil daftar notifikasi milik pelanggan yang sedang login
  Future<List<NotificationItem>> getNotifications({
    int limit = 30,
    int offset = 0,
    NotificationFilter filter = NotificationFilter.all,
    String? searchQuery,
  });

  /// Mengambil jumlah notifikasi yang belum dibaca
  Future<int> getUnreadCount();

  /// Menandai satu notifikasi sebagai sudah dibaca
  Future<void> markAsRead(String notificationId);

  /// Menandai seluruh notifikasi pelanggan sebagai sudah dibaca
  Future<void> markAllAsRead();

  /// Menghapus satu notifikasi pelanggan
  Future<void> deleteNotification(String notificationId);

  /// Menghapus seluruh riwayat notifikasi pelanggan
  Future<void> clearAllNotifications();

  /// Berlangganan aliran notifikasi baru secara real-time via Supabase
  Stream<List<NotificationItem>> subscribeNotifications();
}
