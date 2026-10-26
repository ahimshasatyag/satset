import '../entities/courier_location.dart';
import '../entities/courier_tracking_task.dart';

abstract class CourierLocationTrackingRepository {
  /// Mengambil daftar tugas penugasan pengiriman aktif milik kurir
  Future<List<CourierTrackingTask>> getActiveCourierTasks({String? courierId});

  /// Mengambil koordinat GPS terkini perangkat kurir
  Future<CourierLocation?> getCurrentLocation();

  /// Mendengarkan aliran (stream) perubahan koordinat GPS kurir
  Stream<CourierLocation> getLiveLocationStream({int distanceFilter = 10});

  /// Memeriksa status izin lokasi
  Future<bool> checkLocationPermission();

  /// Meminta izin akses lokasi perangkat kepada kurir
  Future<bool> requestLocationPermission();

  /// Memeriksa apakah layanan GPS perangkat aktif
  Future<bool> isLocationServiceEnabled();

  /// Membuka pengaturan sistem perangkat jika GPS nonaktif atau izin ditolak
  Future<void> openLocationSettings();

  /// Mengirim pembaruan posisi GPS kurir ke tabel t_shipment_locations
  Future<void> sendLocationUpdate({
    required String shipmentId,
    required String courierId,
    required CourierLocation location,
  });

  /// Mengambil catatan koordinat posisi terakhir yang tersimpan untuk pengiriman ini
  Future<CourierLocation?> getLatestSavedLocation({required String shipmentId});

  /// Membaca status preferensi toggle pelacakan kurir
  Future<bool> isTrackingEnabled();

  /// Menyimpan status preferensi toggle pelacakan kurir
  Future<void> setTrackingEnabled(bool enabled);
}
