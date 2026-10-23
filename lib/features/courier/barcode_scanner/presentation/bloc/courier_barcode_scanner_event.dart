import 'package:equatable/equatable.dart';

abstract class CourierBarcodeScannerEvent extends Equatable {
  const CourierBarcodeScannerEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal scanner dan penyelesaian identitas kurir
class BarcodeScannerInitialized extends CourierBarcodeScannerEvent {
  final String? courierId;

  const BarcodeScannerInitialized({this.courierId});

  @override
  List<Object?> get props => [courierId];
}

/// Event saat barcode tertangkap kamera atau dimasukkan secara manual
class BarcodeScanned extends CourierBarcodeScannerEvent {
  final String barcodeValue;
  final bool isManual;
  final bool force;

  const BarcodeScanned(
    this.barcodeValue, {
    this.isManual = false,
    this.force = false,
  });

  @override
  List<Object?> get props => [barcodeValue, isManual, force];
}

/// Event saat kurir menyetujui konfirmasi tindakan operasional paket
class ShipmentActionConfirmed extends CourierBarcodeScannerEvent {
  final String newStatusCode;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const ShipmentActionConfirmed({
    required this.newStatusCode,
    this.notes,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [newStatusCode, notes, latitude, longitude];
}

/// Event untuk memulai atau menghentikan pemindaian kamera
class ScannerToggled extends CourierBarcodeScannerEvent {
  final bool isScanning;

  const ScannerToggled(this.isScanning);

  @override
  List<Object?> get props => [isScanning];
}

/// Event untuk menyalakan atau mematikan lampu senter / flash
class TorchToggled extends CourierBarcodeScannerEvent {
  const TorchToggled();
}

/// Event saat izin kamera diperbarui oleh pengguna
class CameraPermissionStatusChanged extends CourierBarcodeScannerEvent {
  final bool isGranted;
  final bool isCameraAvailable;

  const CameraPermissionStatusChanged({
    required this.isGranted,
    this.isCameraAvailable = true,
  });

  @override
  List<Object?> get props => [isGranted, isCameraAvailable];
}

/// Event untuk mereset scanner dan bersiap memindai paket berikutnya
class ResetScannerForNextPackage extends CourierBarcodeScannerEvent {
  const ResetScannerForNextPackage();
}

/// Event untuk membersihkan riwayat barcode yang telah dipindai sesi ini
class ClearScanHistory extends CourierBarcodeScannerEvent {
  const ClearScanHistory();
}

/// Event untuk menutup pesan error atau banner umpan balik
class ScanErrorDismissed extends CourierBarcodeScannerEvent {
  const ScanErrorDismissed();
}
