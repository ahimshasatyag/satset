import 'package:equatable/equatable.dart';
import '../../domain/entities/navigation_item.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

/// Pengguna berpindah menu tab pada bilah navigasi pelanggan
class NavigationTabChanged extends NavigationEvent {
  final NavigationTab tab;

  const NavigationTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}

/// Kurir berpindah menu tab pada bilah navigasi kurir (tasks, scan, tracking, history, account)
class CourierNavigationTabChanged extends NavigationEvent {
  final CourierNavigationTab tab;

  const CourierNavigationTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}

/// Memeriksa otorisasi kurir pada tabel m_employee (employee_type == 'COURIER')
class NavigationCourierAuthChecked extends NavigationEvent {
  final String userId;
  final String? email;

  const NavigationCourierAuthChecked({
    required this.userId,
    this.email,
  });

  @override
  List<Object?> get props => [userId, email];
}

/// Mendaftarkan subscription Supabase Realtime untuk pembaruan penugasan & notifikasi
class NavigationCourierSubscribed extends NavigationEvent {
  final String courierId;
  final String userId;

  const NavigationCourierSubscribed({
    required this.courierId,
    required this.userId,
  });

  @override
  List<Object?> get props => [courierId, userId];
}

/// Pembaruan internal jumlah tugas aktif kurir (dari query atau realtime stream)
class NavigationActiveTasksCountUpdated extends NavigationEvent {
  final int count;

  const NavigationActiveTasksCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

/// Pembaruan internal jumlah notifikasi belum dibaca
class NavigationUnreadNotificationsCountUpdated extends NavigationEvent {
  final int count;

  const NavigationUnreadNotificationsCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

/// Memuat ulang data penugasan kurir secara manual
class NavigationCourierRefreshRequested extends NavigationEvent {
  final String courierId;

  const NavigationCourierRefreshRequested(this.courierId);

  @override
  List<Object?> get props => [courierId];
}

/// Permintaan keluar (logout) dari bilah navigasi
class NavigationLogoutRequested extends NavigationEvent {
  const NavigationLogoutRequested();
}
