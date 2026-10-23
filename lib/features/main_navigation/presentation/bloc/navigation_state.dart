import 'package:equatable/equatable.dart';
import '../../domain/entities/navigation_item.dart';

class NavigationState extends Equatable {
  /// Tab aktif untuk Pelanggan (Customer)
  final NavigationTab currentTab;

  /// Tab aktif khusus Kurir (Courier) - default: tasks (halaman utama)
  final CourierNavigationTab currentCourierTab;

  /// Jumlah tugas aktif kurir (dari t_shipment_assignments)
  final int activeTasksCount;

  /// Jumlah notifikasi belum dibaca (dari t_notifications)
  final int unreadNotificationsCount;

  /// Status otorisasi akun kurir (employee_type == 'COURIER' pada tabel m_employee)
  final bool? isCourierAuthorized;

  /// Indikator sedang memuat data/validasi
  final bool isLoading;

  /// Indikator sesi Supabase kedaluwarsa
  final bool isSessionExpired;

  /// Pesan error kendala koneksi atau autentikasi
  final String? errorMessage;

  /// Pesan notifikasi sementara
  final String? message;

  const NavigationState({
    this.currentTab = NavigationTab.home,
    this.currentCourierTab = CourierNavigationTab.tasks,
    this.activeTasksCount = 0,
    this.unreadNotificationsCount = 0,
    this.isCourierAuthorized,
    this.isLoading = false,
    this.isSessionExpired = false,
    this.errorMessage,
    this.message,
  });

  /// Indikator apakah kurir memiliki tugas aktif berjalan (untuk pelacakan GPS realtime)
  bool get hasActiveTask => activeTasksCount > 0;

  NavigationState copyWith({
    NavigationTab? currentTab,
    CourierNavigationTab? currentCourierTab,
    int? activeTasksCount,
    int? unreadNotificationsCount,
    bool? isCourierAuthorized,
    bool? isLoading,
    bool? isSessionExpired,
    String? errorMessage,
    String? message,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      currentCourierTab: currentCourierTab ?? this.currentCourierTab,
      activeTasksCount: activeTasksCount ?? this.activeTasksCount,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      isCourierAuthorized: isCourierAuthorized ?? this.isCourierAuthorized,
      isLoading: isLoading ?? this.isLoading,
      isSessionExpired: isSessionExpired ?? this.isSessionExpired,
      errorMessage: errorMessage,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        currentTab,
        currentCourierTab,
        activeTasksCount,
        unreadNotificationsCount,
        isCourierAuthorized,
        isLoading,
        isSessionExpired,
        errorMessage,
        message,
      ];
}
