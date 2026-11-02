import '../../domain/entities/admin_dashboard_stats.dart';

class AdminDashboardStatsModel extends AdminDashboardStats {
  const AdminDashboardStatsModel({
    required super.totalShipments,
    required super.pendingShipments,
    required super.inProcessShipments,
    required super.deliveredShipments,
    required super.failedShipments,
    required super.cancelledShipments,
    required super.totalCustomers,
    required super.totalEmployees,
    required super.totalAdmins,
    required super.totalCouriers,
    required super.activeCouriersCount,
    required super.couriersWithAssignmentCount,
    required super.statusDistributions,
    required super.dailyTrends,
    required super.weeklyTrends,
    required super.monthlyTrends,
    required super.paymentSummary,
  });
}

