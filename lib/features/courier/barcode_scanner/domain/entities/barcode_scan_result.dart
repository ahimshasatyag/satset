import 'package:equatable/equatable.dart';
import 'scanned_shipment.dart';

/// Status klasifikasi hasil pemindaian barcode
enum BarcodeScanStatus {
  /// Pemindaian berhasil dan paket siap diproses oleh kurir
  success,

  /// Barcode tidak terdaftar / tidak ditemukan di sistem
  unregistered,

  /// Paket terdaftar namun bukan tanggung jawab kurir yang sedang login
  notAssigned,

  /// Status pengiriman tidak sesuai / tidak diizinkan untuk diproses lagi
  invalidStatus,

  /// Barcode sudah pernah dipindai dalam sesi ini (pencegahan pemindaian ganda)
  duplicate,

  /// Izin kamera ditolak oleh pengguna
  permissionDenied,

  /// Perangkat kamera tidak tersedia atau mengalami kendala teknis
  cameraUnavailable,

  /// Kesalahan jaringan internet atau server backend
  serverError,
}

/// Hasil evaluasi pemindaian barcode kurir
class BarcodeScanResult extends Equatable {
  /// Status klasifikasi pemindaian
  final BarcodeScanStatus status;

  /// Pesan umpan balik yang ramah pengguna
  final String message;

  /// Saran atau petunjuk tindak lanjut
  final String? guidance;

  /// Nilai barcode yang dipindai
  final String rawBarcode;

  /// Entitas paket yang berhasil ditemukan (null bila tidak terdaftar)
  final ScannedShipment? shipment;

  /// Waktu pemindaian dilakukan
  final DateTime scannedAt;

  const BarcodeScanResult({
    required this.status,
    required this.message,
    this.guidance,
    required this.rawBarcode,
    this.shipment,
    required this.scannedAt,
  });

  /// Factory untuk hasil sukses pemindaian
  factory BarcodeScanResult.success({
    required String rawBarcode,
    required ScannedShipment shipment,
    String? message,
  }) {
    return BarcodeScanResult(
      status: BarcodeScanStatus.success,
      rawBarcode: rawBarcode,
      shipment: shipment,
      message: message ?? 'Paket berhasil dikenali dan siap diproses.',
      guidance: 'Periksa data paket di bawah lalu pilih tindakan operasional.',
      scannedAt: DateTime.now(),
    );
  }

  /// Factory untuk barcode tidak terdaftar
  factory BarcodeScanResult.unregistered({required String rawBarcode}) {
    return BarcodeScanResult(
      status: BarcodeScanStatus.unregistered,
      rawBarcode: rawBarcode,
      message: 'Barcode "$rawBarcode" tidak ditemukan di sistem SatSet.',
      guidance: 'Pastikan barcode atau nomor resi yang dipindai benar dan terdaftar.',
      scannedAt: DateTime.now(),
    );
  }

  /// Factory untuk paket bukan tanggung jawab kurir ini
  factory BarcodeScanResult.notAssigned({
    required String rawBarcode,
    required ScannedShipment shipment,
  }) {
    return BarcodeScanResult(
      status: BarcodeScanStatus.notAssigned,
      rawBarcode: rawBarcode,
      shipment: shipment,
      message: 'Paket resi ${shipment.trackingNumber} bukan merupakan tanggung jawab tugas Anda.',
      guidance: 'Paket ini ditugaskan ke kurir lain atau belum dialokasikan.',
      scannedAt: DateTime.now(),
    );
  }

  /// Factory untuk status paket tidak sesuai
  factory BarcodeScanResult.invalidStatus({
    required String rawBarcode,
    required ScannedShipment shipment,
  }) {
    return BarcodeScanResult(
      status: BarcodeScanStatus.invalidStatus,
      rawBarcode: rawBarcode,
      shipment: shipment,
      message: 'Paket berada pada status "${shipment.statusName}" dan tidak dapat diproses lagi.',
      guidance: 'Periksa detail status pengiriman paket pada daftar tugas kurir.',
      scannedAt: DateTime.now(),
    );
  }

  /// Factory untuk barcode duplikat dalam sesi aktif
  factory BarcodeScanResult.duplicate({
    required String rawBarcode,
    ScannedShipment? shipment,
  }) {
    return BarcodeScanResult(
      status: BarcodeScanStatus.duplicate,
      rawBarcode: rawBarcode,
      shipment: shipment,
      message: 'Barcode "$rawBarcode" telah berhasil dipindai sebelumnya pada sesi ini.',
      guidance: 'Hindari pemindaian ganda agar status tidak tercatat berulang.',
      scannedAt: DateTime.now(),
    );
  }

  /// Factory untuk izin kamera ditolak
  factory BarcodeScanResult.permissionDenied() {
    return BarcodeScanResult(
      status: BarcodeScanStatus.permissionDenied,
      rawBarcode: '',
      message: 'Izin akses kamera ditolak oleh sistem perangkat.',
      guidance: 'Buka pengaturan aplikasi untuk memberikan izin, atau gunakan input barcode manual.',
      scannedAt: DateTime.now(),
    );
  }

  /// Factory untuk kamera tidak tersedia
  factory BarcodeScanResult.cameraUnavailable({String? reason}) {
    return BarcodeScanResult(
      status: BarcodeScanStatus.cameraUnavailable,
      rawBarcode: '',
      message: reason ?? 'Kamera perangkat tidak tersedia atau sedang digunakan aplikasi lain.',
      guidance: 'Gunakan opsi "Input Manual" untuk memasukkan nomor barcode atau nomor resi.',
      scannedAt: DateTime.now(),
    );
  }

  /// Factory untuk kegagalan server atau jaringan
  factory BarcodeScanResult.serverError({
    required String rawBarcode,
    required String errorMessage,
  }) {
    return BarcodeScanResult(
      status: BarcodeScanStatus.serverError,
      rawBarcode: rawBarcode,
      message: 'Gagal memproses pemindaian: $errorMessage',
      guidance: 'Periksa koneksi internet Anda dan coba pindai ulang.',
      scannedAt: DateTime.now(),
    );
  }

  /// Apakah hasil pemindaian dinyatakan sukses operasional
  bool get isSuccess => status == BarcodeScanStatus.success;

  @override
  List<Object?> get props => [status, rawBarcode, shipment, scannedAt];
}
