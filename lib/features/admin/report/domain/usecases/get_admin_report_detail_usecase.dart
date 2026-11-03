import '../entities/admin_report_detail.dart';
import '../entities/admin_report_filter.dart';
import '../repositories/admin_report_repository.dart';

class GetAdminReportDetailUseCase {
  final AdminReportRepository repository;

  const GetAdminReportDetailUseCase(this.repository);

  Future<AdminReportDetail> call({
    required String reportType,
    required int recordId,
    AdminReportFilter? currentFilter,
  }) {
    return repository.getReportDetail(
      reportType: reportType,
      recordId: recordId,
      currentFilter: currentFilter,
    );
  }
}

