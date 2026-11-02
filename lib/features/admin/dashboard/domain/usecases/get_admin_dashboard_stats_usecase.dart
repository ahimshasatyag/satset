import '../entities/admin_activity.dart';
import '../entities/admin_courier_summary.dart';
import '../entities/admin_dashboard_stats.dart';
import '../repositories/admin_dashboard_repository.dart';

class AdminDashboardInitialData {
  final AdminDashboardStats stats;
  final List<AdminCourierSummary> couriers;
  final List<AdminActivity> activities;
  final List<Map<String, dynamic>> statusOptions;
  final List<Map<String, dynamic>> serviceOptions;
  final List<Map<String, dynamic>> courierOptions;

  const AdminDashboardInitialData({
    required this.stats,
    required this.couriers,
    required this.activities,
    required this.statusOptions,
    required this.serviceOptions,
    required this.courierOptions,
  });
}

class GetAdminDashboardStatsUseCase {
  final AdminDashboardRepository repository;

  GetAdminDashboardStatsUseCase(this.repository);

  Future<AdminDashboardInitialData> execute() async {
    final results = await Future.wait([
      repository.getDashboardStats(),
      repository.getCourierSummaries(),
      repository.getRecentActivities(limit: 8),
      repository.getStatusReferences(),
      repository.getServiceTypeReferences(),
      repository.getCourierReferences(),
    ]);

    return AdminDashboardInitialData(
      stats: results[0] as AdminDashboardStats,
      couriers: results[1] as List<AdminCourierSummary>,
      activities: results[2] as List<AdminActivity>,
      statusOptions: results[3] as List<Map<String, dynamic>>,
      serviceOptions: results[4] as List<Map<String, dynamic>>,
      courierOptions: results[5] as List<Map<String, dynamic>>,
    );
  }
}

