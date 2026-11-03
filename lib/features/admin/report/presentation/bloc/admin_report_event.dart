import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_report_filter.dart';

abstract class AdminReportEvent extends Equatable {
  const AdminReportEvent();

  @override
  List<Object?> get props => [];
}

class AdminReportStarted extends AdminReportEvent {
  const AdminReportStarted();
}

class AdminReportRefreshed extends AdminReportEvent {
  const AdminReportRefreshed();
}

class AdminReportTypeChanged extends AdminReportEvent {
  final String reportType;

  const AdminReportTypeChanged(this.reportType);

  @override
  List<Object?> get props => [reportType];
}

class AdminReportDateRangeChanged extends AdminReportEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const AdminReportDateRangeChanged({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class AdminReportFilterUpdated extends AdminReportEvent {
  final String? shipmentStatusCode;
  final String? serviceTypeCode;
  final String? paymentMethod;
  final String? paymentStatus;
  final int? courierId;
  final bool clearCourierId;

  const AdminReportFilterUpdated({
    this.shipmentStatusCode,
    this.serviceTypeCode,
    this.paymentMethod,
    this.paymentStatus,
    this.courierId,
    this.clearCourierId = false,
  });

  @override
  List<Object?> get props => [
        shipmentStatusCode,
        serviceTypeCode,
        paymentMethod,
        paymentStatus,
        courierId,
        clearCourierId,
      ];
}

class AdminReportSearchChanged extends AdminReportEvent {
  final String query;

  const AdminReportSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class AdminReportSortChanged extends AdminReportEvent {
  final String sortColumn;
  final bool sortAscending;

  const AdminReportSortChanged({
    required this.sortColumn,
    required this.sortAscending,
  });

  @override
  List<Object?> get props => [sortColumn, sortAscending];
}

class AdminReportPageChanged extends AdminReportEvent {
  final int page;

  const AdminReportPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class AdminReportFiltersReset extends AdminReportEvent {
  const AdminReportFiltersReset();
}

class AdminReportDetailRequested extends AdminReportEvent {
  final String reportType;
  final int recordId;

  const AdminReportDetailRequested({
    required this.reportType,
    required this.recordId,
  });

  @override
  List<Object?> get props => [reportType, recordId];
}

class AdminReportDetailDismissed extends AdminReportEvent {
  const AdminReportDetailDismissed();
}

class AdminReportExportRequested extends AdminReportEvent {
  final AdminReportExportFormat format;

  const AdminReportExportRequested(this.format);

  @override
  List<Object?> get props => [format];
}

class AdminReportExportDismissed extends AdminReportEvent {
  const AdminReportExportDismissed();
}

class AdminReportClearFeedback extends AdminReportEvent {
  const AdminReportClearFeedback();
}

