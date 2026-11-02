import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_courier_summary.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_shipment_detail.dart';
import '../../domain/entities/admin_shipment_table_item.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_datasource.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final AdminDashboardRemoteDataSource remoteDataSource;

  AdminDashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminDashboardStats> getDashboardStats() {
    return remoteDataSource.getDashboardStats();
  }

  @override
  Future<List<AdminCourierSummary>> getCourierSummaries() {
    return remoteDataSource.getCourierSummaries();
  }

  @override
  Future<List<AdminActivity>> getRecentActivities({int limit = 10}) {
    return remoteDataSource.getRecentActivities(limit: limit);
  }

  @override
  Future<AdminShipmentsPaginatedResult> getPaginatedShipments({
    String? searchQuery,
    String? statusFilter,
    String? serviceFilter,
    int? courierIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 10,
  }) {
    return remoteDataSource.getPaginatedShipments(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      serviceFilter: serviceFilter,
      courierIdFilter: courierIdFilter,
      startDate: startDate,
      endDate: endDate,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<AdminShipmentDetail> getShipmentDetail(int shipmentId) {
    return remoteDataSource.getShipmentDetail(shipmentId);
  }

  @override
  Future<List<Map<String, dynamic>>> getStatusReferences() {
    return remoteDataSource.getStatusReferences();
  }

  @override
  Future<List<Map<String, dynamic>>> getServiceTypeReferences() {
    return remoteDataSource.getServiceTypeReferences();
  }

  @override
  Future<List<Map<String, dynamic>>> getCourierReferences() {
    return remoteDataSource.getCourierReferences();
  }
}

