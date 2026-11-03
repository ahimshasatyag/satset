import '../../domain/entities/admin_customer_detail.dart';
import '../../domain/entities/admin_customer_item.dart';
import '../../domain/repositories/admin_customer_repository.dart';
import '../datasources/admin_customer_remote_datasource.dart';

class AdminCustomerRepositoryImpl implements AdminCustomerRepository {
  final AdminCustomerRemoteDataSource remoteDataSource;

  const AdminCustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminCustomersPaginatedResult> getPaginatedCustomers({
    String? searchQuery,
    String verificationFilter = 'ALL',
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) {
    return remoteDataSource.getPaginatedCustomers(
      searchQuery: searchQuery,
      verificationFilter: verificationFilter,
      startDate: startDate,
      endDate: endDate,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<AdminCustomerDetail> getCustomerDetail(int customerId) {
    return remoteDataSource.getCustomerDetail(customerId);
  }

  @override
  Future<AdminCustomerItem> updateCustomerProfile({
    required int customerId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    double? latitude,
    double? longitude,
    required bool emailVerified,
  }) {
    return remoteDataSource.updateCustomerProfile(
      customerId: customerId,
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      alamatLengkap: alamatLengkap,
      idProvinsi: idProvinsi,
      idKabkot: idKabkot,
      idKecamatan: idKecamatan,
      idKelurahan: idKelurahan,
      latitude: latitude,
      longitude: longitude,
      emailVerified: emailVerified,
    );
  }

  @override
  Future<void> toggleCustomerEmailVerification({
    required int customerId,
    required bool emailVerified,
  }) {
    return remoteDataSource.toggleCustomerEmailVerification(
      customerId: customerId,
      emailVerified: emailVerified,
    );
  }

  @override
  Future<List<AdminWilayahOption>> getProvinsiList() {
    return remoteDataSource.getProvinsiList();
  }

  @override
  Future<List<AdminWilayahOption>> getKabkotList(String kodeProvinsi) {
    return remoteDataSource.getKabkotList(kodeProvinsi);
  }

  @override
  Future<List<AdminWilayahOption>> getKecamatanList(String kodeKabkot) {
    return remoteDataSource.getKecamatanList(kodeKabkot);
  }

  @override
  Future<List<AdminWilayahOption>> getKelurahanList(String kodeKecamatan) {
    return remoteDataSource.getKelurahanList(kodeKecamatan);
  }
}

