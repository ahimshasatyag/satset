import '../entities/shipment.dart';

abstract class ShipmentRepository {
  /// Membuat pesanan pengiriman baru di tabel t_shipments & t_shipment_payments
  Future<OrderShipment> createShipmentOrder(Map<String, dynamic> data);

  /// Alias createShipment
  Future<OrderShipment> createShipment(Map<String, dynamic> data) =>
      createShipmentOrder(data);

  /// Mengambil master jenis layanan pengiriman dari m_service_types
  Future<List<OrderServiceType>> getServiceTypes();

  /// Mengambil daftar provinsi dari m_provinsi
  Future<List<Province>> getProvinces();

  /// Mengambil daftar kabupaten/kota dari m_kabkot berdasarkan kode provinsi
  Future<List<Regency>> getRegencies(String provinceCode);

  /// Mengambil daftar kecamatan dari m_kecamatan berdasarkan kode kabkot
  Future<List<District>> getDistricts(String regencyCode);

  /// Mengambil daftar kelurahan dari m_kelurahan berdasarkan kode kecamatan
  Future<List<Village>> getVillages(String districtCode);

  /// Verifikasi status transaksi pembayaran langsung dari t_shipment_payments
  Future<ShipmentPayment?> verifyPaymentStatus(String shipmentId);

  /// Stream real-time perubahan status pembayaran
  Stream<ShipmentPayment?> streamPaymentStatus(String shipmentId);

  /// Mengambil profil akun pengguna yang sedang login
  Future<Map<String, dynamic>?> getCurrentUserProfile();
}
