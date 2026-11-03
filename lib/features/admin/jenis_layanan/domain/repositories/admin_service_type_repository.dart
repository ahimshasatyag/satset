import '../entities/admin_service_type_detail.dart';
import '../entities/admin_service_type_item.dart';

abstract class AdminServiceTypeRepository {
  Future<bool> verifyAdminAccess();

  Future<AdminServiceTypesPaginatedResult> getPaginatedServiceTypes({
    String? searchQuery,
    String statusFilter = 'ALL',
    String sortColumn = 'id',
    bool sortAscending = true,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminServiceTypeDetail> getServiceTypeDetail(int serviceId);

  Future<AdminServiceTypeItem> createServiceType({
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    bool isActive = true,
  });

  Future<AdminServiceTypeItem> updateServiceType({
    required int serviceId,
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    required bool isActive,
  });

  Future<void> toggleServiceTypeStatus({
    required int serviceId,
    required bool isActive,
  });

  /// Menghapus jenis layanan dari `m_service_types` HANYA JIKA belum pernah digunakan
  /// pada transaksi `t_shipments` (`totalShipmentsCount == 0`).
  Future<void> deleteServiceType(int serviceId);
}

