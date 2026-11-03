import '../entities/admin_report_filter.dart';
import '../repositories/admin_report_repository.dart';

class GetAdminReportReferencesUseCase {
  final AdminReportRepository repository;

  const GetAdminReportReferencesUseCase(this.repository);

  Future<AdminReportFilterReferences> call() {
    return repository.getFilterReferences();
  }
}

