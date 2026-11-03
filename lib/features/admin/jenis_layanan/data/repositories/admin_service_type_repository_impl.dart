import '../../domain/entities/admin_service_type_detail.dart';
import '../../domain/entities/admin_service_type_item.dart';
import '../../domain/repositories/admin_service_type_repository.dart';
import '../datasources/admin_service_type_remote_datasource.dart';

class AdminServiceTypeRepositoryImpl implements AdminServiceTypeRepository {
  final AdminServiceTypeRemoteDataSource remoteDataSource;

  const AdminServiceTypeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminServiceTypesPaginatedResult> getPaginatedServiceTypes({
    String? searchQuery,
    String statusFilter = 'ALL',
    String sortColumn = 'id',
    bool sortAscending = true,
    int page = 1,
    int pageSize = 10,
  }) {
    return remoteDataSource.getPaginatedServiceTypes(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<AdminServiceTypeDetail> getServiceTypeDetail(int serviceId) {
    return remoteDataSource.getServiceTypeDetail(serviceId);
  }

  @override
  Future<AdminServiceTypeItem> createServiceType({
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    bool isActive = true,
  }) {
    return remoteDataSource.createServiceType(
      kode: kode,
      namaLayanan: namaLayanan,
      estimasiHariMin: estimasiHariMin,
      estimasiHariMax: estimasiHariMax,
      deskripsi: deskripsi,
      baseTariffPerKg: baseTariffPerKg,
      isActive: isActive,
    );
  }

  @override
  Future<AdminServiceTypeItem> updateServiceType({
    required int serviceId,
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    required bool isActive,
  }) {
    return remoteDataSource.updateServiceType(
      serviceId: serviceId,
      kode: kode,
      namaLayanan: namaLayanan,
      estimasiHariMin: estimasiHariMin,
      estimasiHariMax: estimasiHariMax,
      deskripsi: deskripsi,
      baseTariffPerKg: baseTariffPerKg,
      isActive: isActive,
    );
  }

  @override
  Future<void> toggleServiceTypeStatus({
    required int serviceId,
    required bool isActive,
  }) {
    return remoteDataSource.toggleServiceTypeStatus(
      serviceId: serviceId,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteServiceType(int serviceId) {
    return remoteDataSource.deleteServiceType(serviceId);
  }
}

