import '../entities/admin_report_detail.dart';
import '../entities/admin_report_filter.dart';
import '../entities/admin_report_models.dart';

abstract class AdminReportRepository {
  /// Memastikan halaman hanya diakses oleh admin terautentikasi (m_employee.id_users_role = 1)
  Future<bool> verifyAdminAccess();

  /// Mengambil daftar referensi filter (m_shipment_statuses, m_service_types, m_employee kurir)
  Future<AdminReportFilterReferences> getFilterReferences();

  /// Mengambil data laporan teragregasi, grafik, dan tabel sesuai filter
  Future<AdminReportDataResult> getReportData(AdminReportFilter filter);

  /// Mengambil detail laporan beserta data pendukung (resi, layanan, status, kurir, pembayaran, tracking, bukti, lokasi)
  Future<AdminReportDetail> getReportDetail({
    required String reportType,
    required int recordId,
    AdminReportFilter? currentFilter,
  });
}

