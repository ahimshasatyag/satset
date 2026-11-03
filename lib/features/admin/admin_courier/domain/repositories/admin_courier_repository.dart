import '../entities/admin_courier_detail.dart';
import '../entities/admin_courier_item.dart';

abstract class AdminCourierRepository {
  Future<bool> verifyAdminAccess();

  Future<AdminCouriersPaginatedResult> getPaginatedCouriers({
    String? searchQuery,
    String accountStatusFilter = 'ALL',
    String activityStatusFilter = 'ALL',
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminCourierDetail> getCourierDetail(int courierId);

  Future<AdminCourierItem> createCourierAccount({
    required String namaLengkap,
    required String email,
    required String noHp,
    required String password,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
    bool isActive = true,
  });

  Future<AdminCourierItem> updateCourierProfile({
    required int courierId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? fotoUrl,
    String? newPassword,
    required bool isActive,
  });

  Future<void> toggleCourierAccountStatus({
    required int courierId,
    required bool isActive,
  });

  Future<void> unassignCourierTask({
    required int assignmentId,
    required int shipmentId,
    String? reason,
  });
}

