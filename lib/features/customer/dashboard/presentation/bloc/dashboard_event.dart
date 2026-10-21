import 'package:equatable/equatable.dart';
import '../../domain/entities/shipment.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Permintaan inisialisasi awal dashboard customer & koneksi real-time stream Supabase
class DashboardInitializeRequested extends DashboardEvent {
  final String? userId;
  final int? customerId;

  const DashboardInitializeRequested({
    this.userId,
    this.customerId,
  });

  @override
  List<Object?> get props => [userId, customerId];
}

/// Event ketika snapshot baru diterima dari Stream Realtime Supabase
class DashboardLiveShipmentReceived extends DashboardEvent {
  final Shipment? shipment;

  const DashboardLiveShipmentReceived(this.shipment);

  @override
  List<Object?> get props => [shipment];
}

/// Melacak nomor resi dari kolom pencarian Smart Tracking Bar
class DashboardTrackNumberSubmitted extends DashboardEvent {
  final String trackingNumber;

  const DashboardTrackNumberSubmitted(this.trackingNumber);

  @override
  List<Object?> get props => [trackingNumber];
}

/// Hasil pindai barcode/QR dari dialog scanner
class DashboardBarcodeScanned extends DashboardEvent {
  final String scannedCode;

  const DashboardBarcodeScanned(this.scannedCode);

  @override
  List<Object?> get props => [scannedCode];
}

/// Mengubah filter kategori status kartu ringkasan
class DashboardStatusFilterChanged extends DashboardEvent {
  final String? statusFilter; // null or 'waiting', 'process', 'transit', 'delivered'

  const DashboardStatusFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Bersihkan dialog/hasil pencarian
class DashboardClearSearchResult extends DashboardEvent {
  const DashboardClearSearchResult();
}

/// Pengguna mengetuk lonceng notifikasi
class DashboardNotificationTapped extends DashboardEvent {
  const DashboardNotificationTapped();
}

/// Refresh manual ketika pull-to-refresh
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

/// Hapus seluruh riwayat pencarian
class DashboardClearHistoryRequested extends DashboardEvent {
  const DashboardClearHistoryRequested();
}
