import '../entities/shipment.dart';
import '../entities/user_profile.dart';

/// Kontrak Repository Dashboard Customer SatSet Delivery
abstract class DashboardRepository {
  /// Stream koneksi real-time via Supabase Realtime
  /// yang menyiarkan pembaruan status dan pergerakan pengiriman secara instan
  Stream<Shipment?> getLiveActiveShipmentStream({int? customerId});

  /// Mengambil data pengiriman aktif milik pelanggan saat ini (jika ada)
  Future<Shipment?> getActiveShipment({int? customerId});

  /// Mengambil daftar riwayat pengiriman terbaru milik pelanggan
  Future<List<Shipment>> getRecentShipments({
    int? customerId,
    int limit = 10,
    String? statusFilter,
  });

  /// Mengambil ringkasan jumlah paket pelanggan berdasarkan 4 kategori status
  Future<ShipmentStatusSummary> getShipmentStatusSummary({int? customerId});

  /// Mencari dan melacak status paket berdasarkan nomor resi atau barcode
  Future<Shipment?> trackShipment(String trackingNumber);

  /// Mengambil data profil pelanggan dari m_users
  Future<UserProfile> getUserProfile({String? userId});

  /// Mengambil riwayat pencarian nomor resi lokal
  Future<List<String>> getSearchHistory();

  /// Menambahkan nomor resi ke riwayat pencarian
  Future<void> addSearchHistory(String trackingNumber);

  /// Menghapus seluruh riwayat pencarian nomor resi
  Future<void> clearSearchHistory();

  /// Menandai pembaruan notifikasi sebagai telah dibaca
  Future<void> markNotificationsAsRead();
}
