import 'package:equatable/equatable.dart';

/// Enum 5 menu utama pada bilah navigasi bawah untuk Pelanggan (Customer)
enum NavigationTab {
  home('Beranda'),
  liveTrack('Lacak Live'),
  send('Kirim'),
  orders('Pesanan'),
  account('Akun');

  final String label;
  const NavigationTab(this.label);
}

/// Enum menu utama pada bilah navigasi bawah khusus Kurir (Courier)
/// Sesuai PRD: tasks (utama), scan, tracking_courier, history, account
enum CourierNavigationTab {
  tasks('Tugas'),
  scan('Scan'),
  trackingCourier('Pelacakan'),
  history('Riwayat'),
  account('Akun');

  final String label;
  const CourierNavigationTab(this.label);
}

/// Informasi lencana (badge) umum pada bilah navigasi
class NavigationBadgeInfo extends Equatable {
  final int badgeCount;
  final bool hasUnreadNotifications;

  const NavigationBadgeInfo({
    this.badgeCount = 0,
    this.hasUnreadNotifications = true,
  });

  @override
  List<Object?> get props => [badgeCount, hasUnreadNotifications];
}

/// Informasi lencana (badge) dan status tugas khusus Kurir (Courier)
class CourierBadgeInfo extends Equatable {
  final int activeTasksCount;
  final int unreadNotificationsCount;
  final bool isTrackingActive;

  const CourierBadgeInfo({
    this.activeTasksCount = 0,
    this.unreadNotificationsCount = 0,
    this.isTrackingActive = false,
  });

  bool get hasActiveTask => activeTasksCount > 0;

  CourierBadgeInfo copyWith({
    int? activeTasksCount,
    int? unreadNotificationsCount,
    bool? isTrackingActive,
  }) {
    return CourierBadgeInfo(
      activeTasksCount: activeTasksCount ?? this.activeTasksCount,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
    );
  }

  @override
  List<Object?> get props => [
        activeTasksCount,
        unreadNotificationsCount,
        isTrackingActive,
      ];
}
