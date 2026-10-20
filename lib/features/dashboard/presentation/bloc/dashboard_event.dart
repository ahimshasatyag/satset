import 'package:equatable/equatable.dart';
import '../../domain/entities/shipment.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Permintaan inisialisasi awal dashboard & koneksi real-time stream
class DashboardInitializeRequested extends DashboardEvent {
  const DashboardInitializeRequested();
}

/// Event internal ketika snapshot baru diterima dari Stream Real-time
class DashboardLiveShipmentReceived extends DashboardEvent {
  final Shipment shipment;

  const DashboardLiveShipmentReceived(this.shipment);

  @override
  List<Object?> get props => [shipment];
}

/// Melacak nomor resi dari Smart Tracking Bar
class DashboardTrackNumberSubmitted extends DashboardEvent {
  final String trackingNumber;

  const DashboardTrackNumberSubmitted(this.trackingNumber);

  @override
  List<Object?> get props => [trackingNumber];
}

/// Hasil pindai barcode/QR dari scanner
class DashboardBarcodeScanned extends DashboardEvent {
  final String scannedCode;

  const DashboardBarcodeScanned(this.scannedCode);

  @override
  List<Object?> get props => [scannedCode];
}

/// Pengguna mengetuk ikon lonceng notifikasi
class DashboardNotificationTapped extends DashboardEvent {
  const DashboardNotificationTapped();
}

/// Refresh manual jika pengguna melakukan swipe-to-refresh
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}
