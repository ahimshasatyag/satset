import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_report_detail.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/entities/admin_report_models.dart';
import '../../domain/usecases/export_admin_report_usecase.dart';

enum AdminReportStatus {
  initial,
  loading,
  loaded,
  unauthorized,
  error,
}

class AdminReportState extends Equatable {
  final AdminReportStatus status;
  final AdminReportFilter filter;
  final AdminReportFilterReferences references;
  final AdminReportDataResult reportData;
  final bool isRefreshing;
  final bool isDetailLoading;
  final AdminReportDetail? selectedDetail;
  final AdminReportExportOutput? activeExportOutput;
  final String? dateValidationError;
  final String? errorMessage;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const AdminReportState({
    this.status = AdminReportStatus.initial,
    this.filter = const AdminReportFilter(),
    this.references = AdminReportFilterReferences.empty,
    this.reportData = AdminReportDataResult.empty,
    this.isRefreshing = false,
    this.isDetailLoading = false,
    this.selectedDetail,
    this.activeExportOutput,
    this.dateValidationError,
    this.errorMessage,
    this.actionSuccessMessage,
    this.actionErrorMessage,
  });

  AdminReportState copyWith({
    AdminReportStatus? status,
    AdminReportFilter? filter,
    AdminReportFilterReferences? references,
    AdminReportDataResult? reportData,
    bool? isRefreshing,
    bool? isDetailLoading,
    AdminReportDetail? selectedDetail,
    bool clearSelectedDetail = false,
    AdminReportExportOutput? activeExportOutput,
    bool clearActiveExport = false,
    String? dateValidationError,
    bool clearDateValidationError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionSuccessMessage,
    bool clearActionSuccess = false,
    String? actionErrorMessage,
    bool clearActionError = false,
  }) {
    return AdminReportState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      references: references ?? this.references,
      reportData: reportData ?? this.reportData,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      selectedDetail:
          clearSelectedDetail ? null : (selectedDetail ?? this.selectedDetail),
      activeExportOutput: clearActiveExport
          ? null
          : (activeExportOutput ?? this.activeExportOutput),
      dateValidationError: clearDateValidationError
          ? null
          : (dateValidationError ?? this.dateValidationError),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionSuccessMessage: clearActionSuccess
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      actionErrorMessage: clearActionError
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        filter,
        references,
        reportData,
        isRefreshing,
        isDetailLoading,
        selectedDetail,
        activeExportOutput,
        dateValidationError,
        errorMessage,
        actionSuccessMessage,
        actionErrorMessage,
      ];
}

