import '../entities/admin_customer_detail.dart';
import '../entities/admin_customer_item.dart';

abstract class AdminCustomerRepository {
  Future<bool> verifyAdminAccess();

  Future<AdminCustomersPaginatedResult> getPaginatedCustomers({
    String? searchQuery,
    String verificationFilter = 'ALL',
    DateTime? startDate,
    DateTime? endDate,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminCustomerDetail> getCustomerDetail(int customerId);

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
  });

  Future<void> toggleCustomerEmailVerification({
    required int customerId,
    required bool emailVerified,
  });

  Future<List<AdminWilayahOption>> getProvinsiList();
  Future<List<AdminWilayahOption>> getKabkotList(String kodeProvinsi);
  Future<List<AdminWilayahOption>> getKecamatanList(String kodeKabkot);
  Future<List<AdminWilayahOption>> getKelurahanList(String kodeKecamatan);
}

