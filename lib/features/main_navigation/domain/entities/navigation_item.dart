import 'package:equatable/equatable.dart';

/// Enum 5 menu utama pada bilah navigasi bawah
enum NavigationTab {
  home('Beranda'),
  liveTrack('Lacak Live'),
  send('Kirim'),
  orders('Pesanan'),
  account('Akun');

  final String label;
  const NavigationTab(this.label);
}

/// Informasi lencana (badge) pada bilah navigasi
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
