import '../entities/admin_activity.dart';
import '../entities/admin_courier_summary.dart';
import '../entities/admin_dashboard_stats.dart';
import '../entities/admin_shipment_detail.dart';
import '../entities/admin_shipment_table_item.dart';

/// Kontrak repositori untuk Dashboard Admin Website SatSet
abstract class AdminDashboardRepository {
  /// Validasi apakah sesi login yang aktif merupakan akun Admin resmi
  /// (id_users_role = 1 pada m_users_role / m_employee.employee_type = 'ADMIN')
  Future<bool> verifyAdminAccess();

  /// Mengambil data statistik agregat dashboard admin dari Supabase
  Future<AdminDashboardStats> getDashboardStats();

  /// Mengambil daftar ringkasan penugasan kurir
  Future<List<AdminCourierSummary>> getCourierSummaries();

  /// Mengambil feed aktivitas operasional terkini dari t_shipment_tracking
  Future<List<AdminActivity>> getRecentActivities({int limit = 10});

  /// Mengambil daftar pengiriman dengan pagination, pencarian, dan filter
  Future<AdminShipmentsPaginatedResult> getPaginatedShipments({
    String? searchQuery,
    String? statusFilter,
    String? serviceFilter,
    int? courierIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 10,
  });

  /// Mengambil detail lengkap satu pengiriman beserta kronologi pelacakannya
  Future<AdminShipmentDetail> getShipmentDetail(int shipmentId);

  /// Mengambil daftar filter referensi status pengiriman
  Future<List<Map<String, dynamic>>> getStatusReferences();

  /// Mengambil daftar filter referensi jenis layanan (m_service_types)
  Future<List<Map<String, dynamic>>> getServiceTypeReferences();

  /// Mengambil daftar pegawai kurir aktif untuk filter
  Future<List<Map<String, dynamic>>> getCourierReferences();
}

