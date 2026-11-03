import '../../domain/entities/admin_courier_detail.dart';
import '../../domain/entities/admin_courier_item.dart';
import '../../domain/repositories/admin_courier_repository.dart';
import '../datasources/admin_courier_remote_datasource.dart';

class AdminCourierRepositoryImpl implements AdminCourierRepository {
  final AdminCourierRemoteDataSource remoteDataSource;

  const AdminCourierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminCouriersPaginatedResult> getPaginatedCouriers({
    String? searchQuery,
    String accountStatusFilter = 'ALL',
    String activityStatusFilter = 'ALL',
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  }) {
    return remoteDataSource.getPaginatedCouriers(
      searchQuery: searchQuery,
      accountStatusFilter: accountStatusFilter,
      activityStatusFilter: activityStatusFilter,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<AdminCourierDetail> getCourierDetail(int courierId) {
    return remoteDataSource.getCourierDetail(courierId);
  }

  @override
  Future<AdminCourierItem> createCourierAccount({
    required String namaLengkap,
    required String email,
    required String noHp,
    required String password,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
    bool isActive = true,
  }) {
    return remoteDataSource.createCourierAccount(
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      password: password,
      employeeCode: employeeCode,
      alamatLengkap: alamatLengkap,
      fotoUrl: fotoUrl,
      isActive: isActive,
    );
  }

  @override
  Future<AdminCourierItem> updateCourierProfile({
    required int courierId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? fotoUrl,
    String? newPassword,
    required bool isActive,
  }) {
    return remoteDataSource.updateCourierProfile(
      courierId: courierId,
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      alamatLengkap: alamatLengkap,
      fotoUrl: fotoUrl,
      newPassword: newPassword,
      isActive: isActive,
    );
  }

  @override
  Future<void> toggleCourierAccountStatus({
    required int courierId,
    required bool isActive,
  }) {
    return remoteDataSource.toggleCourierAccountStatus(
      courierId: courierId,
      isActive: isActive,
    );
  }

  @override
  Future<void> unassignCourierTask({
    required int assignmentId,
    required int shipmentId,
    String? reason,
  }) {
    return remoteDataSource.unassignCourierTask(
      assignmentId: assignmentId,
      shipmentId: shipmentId,
      reason: reason,
    );
  }
}

