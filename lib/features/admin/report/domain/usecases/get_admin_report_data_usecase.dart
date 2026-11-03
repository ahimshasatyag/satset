import '../entities/admin_report_filter.dart';
import '../entities/admin_report_models.dart';
import '../repositories/admin_report_repository.dart';

class GetAdminReportDataUseCase {
  final AdminReportRepository repository;

  const GetAdminReportDataUseCase(this.repository);

  Future<AdminReportDataResult> call(AdminReportFilter filter) {
    final validationError = filter.validateDateRange();
    if (validationError != null) {
      throw Exception(validationError);
    }
    return repository.getReportData(filter);
  }
}

