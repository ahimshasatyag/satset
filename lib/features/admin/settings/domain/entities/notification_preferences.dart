import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool notifyNewShipmentOrders;
  final bool notifyShipmentStatusChanges;
  final bool notifyCourierAssignments;
  final bool notifyPaymentTransactions;
  final bool notifyFailedDeliveries;
  final bool soundAlertEnabled;
  final int totalExistingNotifications;
  final int unreadNotificationsCount;
  final String backendNote;

  const NotificationPreferences({
    this.notifyNewShipmentOrders = true,
    this.notifyShipmentStatusChanges = true,
    this.notifyCourierAssignments = true,
    this.notifyPaymentTransactions = true,
    this.notifyFailedDeliveries = true,
    this.soundAlertEnabled = false,
    this.totalExistingNotifications = 0,
    this.unreadNotificationsCount = 0,
    this.backendNote =
        'Tabel "t_notifications" pada Supabase menyimpan riwayat pengiriman notifikasi ke pengguna. Preferensi aktivasi notifikasi admin ini disimpan di penyimpanan preferensi lokal browser karena skema database saat ini belum menyediakan tabel terpisah untuk konfigurasi preferensi notifikasi per pengguna.',
  });

  NotificationPreferences copyWith({
    bool? notifyNewShipmentOrders,
    bool? notifyShipmentStatusChanges,
    bool? notifyCourierAssignments,
    bool? notifyPaymentTransactions,
    bool? notifyFailedDeliveries,
    bool? soundAlertEnabled,
    int? totalExistingNotifications,
    int? unreadNotificationsCount,
    String? backendNote,
  }) {
    return NotificationPreferences(
      notifyNewShipmentOrders:
          notifyNewShipmentOrders ?? this.notifyNewShipmentOrders,
      notifyShipmentStatusChanges:
          notifyShipmentStatusChanges ?? this.notifyShipmentStatusChanges,
      notifyCourierAssignments:
          notifyCourierAssignments ?? this.notifyCourierAssignments,
      notifyPaymentTransactions:
          notifyPaymentTransactions ?? this.notifyPaymentTransactions,
      notifyFailedDeliveries:
          notifyFailedDeliveries ?? this.notifyFailedDeliveries,
      soundAlertEnabled: soundAlertEnabled ?? this.soundAlertEnabled,
      totalExistingNotifications:
          totalExistingNotifications ?? this.totalExistingNotifications,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      backendNote: backendNote ?? this.backendNote,
    );
  }

  @override
  List<Object?> get props => [
        notifyNewShipmentOrders,
        notifyShipmentStatusChanges,
        notifyCourierAssignments,
        notifyPaymentTransactions,
        notifyFailedDeliveries,
        soundAlertEnabled,
        totalExistingNotifications,
        unreadNotificationsCount,
        backendNote,
      ];
}

