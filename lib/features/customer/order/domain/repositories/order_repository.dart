import '../entities/order_shipment.dart';

abstract class OrderRepository {
  /// Mengambil daftar pesanan berdasarkan arah (Kiriman Saya / Paket Masuk) dan filter
  Future<List<OrderShipment>> getOrders({
    required OrderDirection direction,
    OrderFilterStatus filter = OrderFilterStatus.all,
  });

  /// Stream jumlah paket aktif yang sedang berjalan untuk lencana (badge) menu Pesanan
  Stream<int> getActiveOrdersCountStream();

  /// Membuat pesanan pengiriman baru via formulir pengiriman
  Future<OrderShipment> createShipmentOrder(Map<String, dynamic> data);

  /// Mengambil master jenis layanan pengiriman dari m_service_types
  Future<List<OrderServiceType>> getServiceTypes();

  /// Mengambil daftar provinsi dari m_provinsi
  Future<List<Province>> getProvinces();

  /// Mengambil daftar kabupaten/kota dari m_kabkot
  Future<List<Regency>> getRegencies(String provinceCode);

  /// Mengambil daftar kecamatan dari m_kecamatan
  Future<List<District>> getDistricts(String regencyCode);

  /// Mengambil daftar kelurahan dari m_kelurahan
  Future<List<Village>> getVillages(String districtCode);

  /// Verifikasi status transaksi pembayaran langsung dari t_shipment_payments
  Future<ShipmentPayment?> verifyPaymentStatus(String shipmentId);

  /// Stream real-time perubahan status pembayaran
  Stream<ShipmentPayment?> streamPaymentStatus(String shipmentId);

  /// Mengambil profil akun pengguna yang sedang login
  Future<Map<String, dynamic>?> getCurrentUserProfile();
}
