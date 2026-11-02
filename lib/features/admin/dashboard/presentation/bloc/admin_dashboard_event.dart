import 'package:equatable/equatable.dart';

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal dashboard admin (verifikasi akses, muat statistik & tabel)
class AdminDashboardStarted extends AdminDashboardEvent {
  const AdminDashboardStarted();
}

/// Refresh manual seluruh data dashboard admin
class AdminDashboardRefreshed extends AdminDashboardEvent {
  const AdminDashboardRefreshed();
}

/// Perubahan periode grafik tren pengiriman (Harian / Mingguan / Bulanan)
class AdminDashboardTrendPeriodChanged extends AdminDashboardEvent {
  final String period; // 'DAILY', 'WEEKLY', 'MONTHLY'

  const AdminDashboardTrendPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

/// Pencarian nomor resi / nama pengirim / penerima
class AdminDashboardSearchQueryChanged extends AdminDashboardEvent {
  final String query;

  const AdminDashboardSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Perubahan filter status pada tabel pengiriman
class AdminDashboardStatusFilterChanged extends AdminDashboardEvent {
  final String status;

  const AdminDashboardStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Perubahan filter layanan pada tabel pengiriman
class AdminDashboardServiceFilterChanged extends AdminDashboardEvent {
  final String service;

  const AdminDashboardServiceFilterChanged(this.service);

  @override
  List<Object?> get props => [service];
}

/// Perubahan filter tanggal rentang pada tabel pengiriman
class AdminDashboardDateRangeFilterChanged extends AdminDashboardEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminDashboardDateRangeFilterChanged({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Pindah halaman tabel pengiriman (Pagination)
class AdminDashboardPageChanged extends AdminDashboardEvent {
  final int page;

  const AdminDashboardPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

/// Buka dialog modal detail pengiriman dan kronologi jejak
class AdminDashboardShipmentDetailRequested extends AdminDashboardEvent {
  final int shipmentId;

  const AdminDashboardShipmentDetailRequested(this.shipmentId);

  @override
  List<Object?> get props => [shipmentId];
}

/// Tutup dialog modal detail pengiriman
class AdminDashboardShipmentDetailDismissed extends AdminDashboardEvent {
  const AdminDashboardShipmentDetailDismissed();
}

/// Pembaruan real-time dari Supabase Realtime channel
class AdminDashboardRealtimeTriggered extends AdminDashboardEvent {
  const AdminDashboardRealtimeTriggered();
}

