import '../entities/barcode_scan_log.dart';
import '../entities/barcode_scan_result.dart';
import '../entities/scanned_shipment.dart';

/// Kontrak repositori untuk fitur pemindaian barcode khusus kurir
abstract class CourierBarcodeScannerRepository {
  /// Memindai dan memvalidasi nilai barcode terhadap basis data pengiriman
  /// dan penugasan kurir aktif
  Future<BarcodeScanResult> scanBarcode({
    required String barcodeValue,
    required String courierId,
    bool force = false,
  });

  /// Memproses tindakan operasional paket yang telah dipindai
  /// (misalnya Konfirmasi Pickup, Mulai Antar, Selesai Antar)
  Future<BarcodeScanResult> processShipmentAction({
    required String shipmentId,
    required String? assignmentId,
    required String newStatusCode,
    required String courierId,
    String? notes,
    double? latitude,
    double? longitude,
  });

  /// Mencatat riwayat log audit pemindaian ke tabel t_barcode_scans
  Future<void> recordScanAudit(BarcodeScanLog scanLog);

  /// Mengambil daftar riwayat barcode yang dipindai dalam sesi kurir saat ini
  List<String> getRecentScannedCodes();

  /// Membersihkan jejak sesi pemindaian saat ini
  void clearScanHistory();

  /// Mendengarkan perubahan data real-time pada paket yang sedang dipindai
  Stream<ScannedShipment?> streamShipmentUpdates(String shipmentId);

  /// Menyelesaikan ID kurir aktif dari sesi lokal atau Supabase
  Future<String> resolveCourierId({String? overrideId});
}
