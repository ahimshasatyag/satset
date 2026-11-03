import '../entities/admin_assignable_courier.dart';
import '../entities/admin_delivery_detail.dart';
import '../entities/admin_delivery_item.dart';

abstract class AdminDeliveryRepository {
  /// Memverifikasi apakah pengguna yang aktif adalah Administrator (`m_employee.id_users_role = 1`)
  Future<bool> verifyAdminAccess();

  /// Mengambil daftar pengiriman terpaginasi beserta ringkasan tab dan seluruh filter operasional
  Future<AdminDeliveriesPaginatedResult> getPaginatedDeliveries({
    String tabCategory = AdminDeliveryTab.all,
    String? searchQuery,
    String? statusFilter,
    String? paymentMethodFilter,
    String? paymentStatusFilter,
    String? serviceFilter,
    String? courierFilter,
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });

  /// Mengambil detail lengkap pengiriman (termasuk customer, pembayaran, penugasan kurir, tracking, dan lokasi kurir)
  Future<AdminDeliveryDetail> getDeliveryDetail(int shipmentId);

  /// Mengambil daftar kurir dari `m_employee` dengan `id_users_role = 2` beserta beban tugas aktifnya
  Future<List<AdminAssignableCourier>> getAssignableCouriers();

  /// Mengonfirmasi pesanan pengiriman (mengubah status menjadi CONFIRMED dan mencatat di `t_shipment_tracking`)
  Future<void> confirmShipmentOrder({
    required int shipmentId,
    String? notes,
  });

  /// Menugaskan atau memperbarui penugasan kurir pada `t_shipment_assignments` dengan validasi anti-bentrok
  Future<void> assignCourierToShipment({
    required int shipmentId,
    required int courierId,
    String? notes,
  });

  /// Memperbarui status pengiriman secara tervalidasi dan mencatat audit kronologi di `t_shipment_tracking`
  Future<void> updateShipmentStatus({
    required int shipmentId,
    required String targetStatusCode,
    String? lokasiNama,
    String? notes,
  });

  /// Menangani pengiriman gagal (Penjadwalan ulang pengantaran, ganti kurir, pengembalian/return, atau pembatalan)
  Future<void> handleFailedDelivery({
    required int shipmentId,
    required String resolutionAction,
    int? reassignCourierId,
    String? notes,
  });

  /// Mengambil referensi daftar status pengiriman dari `m_shipment_statuses`
  Future<List<Map<String, dynamic>>> getStatusReferences();

  /// Mengambil referensi daftar jenis layanan dari `m_service_types`
  Future<List<Map<String, dynamic>>> getServiceTypeReferences();
}

