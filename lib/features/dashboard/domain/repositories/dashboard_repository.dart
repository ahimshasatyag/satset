import '../entities/shipment.dart';
import '../entities/user_profile.dart';

/// Kontrak Repository Dashboard Pengiriman SatSet
abstract class DashboardRepository {
  /// Stream koneksi real-time (WebSocket / Firestore snapshot)
  /// yang menyiarkan pembaruan status dan pergerakan kurir secara instan
  Stream<Shipment> getLiveActiveShipmentStream();

  /// Mengambil data pengiriman aktif saat ini
  Future<Shipment> getActiveShipment();

  /// Mengambil daftar riwayat paket terbaru
  Future<List<Shipment>> getRecentShipments();

  /// Mencari dan melacak status paket berdasarkan nomor resi
  Future<Shipment?> trackShipment(String trackingNumber);

  /// Mengambil data profil dan lokasi GPS pengguna
  Future<UserProfile> getUserProfile();

  /// Menandai pembaruan notifikasi kurir sebagai telah dibaca
  Future<void> markNotificationsAsRead();
}
