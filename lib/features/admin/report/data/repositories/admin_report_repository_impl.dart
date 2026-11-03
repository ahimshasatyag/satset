import '../../domain/entities/admin_report_detail.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/entities/admin_report_models.dart';
import '../../domain/repositories/admin_report_repository.dart';
import '../datasources/admin_report_remote_datasource.dart';

class AdminReportRepositoryImpl implements AdminReportRepository {
  final AdminReportRemoteDataSource remoteDataSource;

  const AdminReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> verifyAdminAccess() {
    return remoteDataSource.verifyAdminAccess();
  }

  @override
  Future<AdminReportFilterReferences> getFilterReferences() {
    return remoteDataSource.getFilterReferences();
  }

  @override
  Future<AdminReportDataResult> getReportData(AdminReportFilter filter) {
    return remoteDataSource.getReportData(filter);
  }

  @override
  Future<AdminReportDetail> getReportDetail({
    required String reportType,
    required int recordId,
    AdminReportFilter? currentFilter,
  }) {
    return remoteDataSource.getReportDetail(
      reportType: reportType,
      recordId: recordId,
      currentFilter: currentFilter,
    );
  }
}

