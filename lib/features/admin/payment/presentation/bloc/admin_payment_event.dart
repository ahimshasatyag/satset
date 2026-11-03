import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_payment_item.dart';

abstract class AdminPaymentEvent extends Equatable {
  const AdminPaymentEvent();

  @override
  List<Object?> get props => [];
}

class AdminPaymentStarted extends AdminPaymentEvent {
  const AdminPaymentStarted();
}

class AdminPaymentRefreshed extends AdminPaymentEvent {
  const AdminPaymentRefreshed();
}

class AdminPaymentRealtimeUpdated extends AdminPaymentEvent {
  const AdminPaymentRealtimeUpdated();
}

class AdminPaymentTabSelected extends AdminPaymentEvent {
  final String tabCategory;

  const AdminPaymentTabSelected(this.tabCategory);

  @override
  List<Object?> get props => [tabCategory];
}

class AdminPaymentPeriodChanged extends AdminPaymentEvent {
  final AdminPaymentPeriod period;

  const AdminPaymentPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

class AdminPaymentSearchChanged extends AdminPaymentEvent {
  final String searchQuery;

  const AdminPaymentSearchChanged(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}

class AdminPaymentFiltersUpdated extends AdminPaymentEvent {
  final String? methodFilter;
  final String? statusFilter;
  final String? jenisBankFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final num? minAmount;
  final num? maxAmount;
  final bool clearDates;
  final bool clearAmounts;

  const AdminPaymentFiltersUpdated({
    this.methodFilter,
    this.statusFilter,
    this.jenisBankFilter,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.clearDates = false,
    this.clearAmounts = false,
  });

  @override
  List<Object?> get props => [
        methodFilter,
        statusFilter,
        jenisBankFilter,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        clearDates,
        clearAmounts,
      ];
}

class AdminPaymentFiltersReset extends AdminPaymentEvent {
  const AdminPaymentFiltersReset();
}

class AdminPaymentSortChanged extends AdminPaymentEvent {
  final String sortColumn;

  const AdminPaymentSortChanged(this.sortColumn);

  @override
  List<Object?> get props => [sortColumn];
}

class AdminPaymentPageChanged extends AdminPaymentEvent {
  final int page;

  const AdminPaymentPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class AdminPaymentDetailRequested extends AdminPaymentEvent {
  final int paymentId;

  const AdminPaymentDetailRequested(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

class AdminPaymentDetailDismissed extends AdminPaymentEvent {
  const AdminPaymentDetailDismissed();
}

class AdminPaymentReconcileRequested extends AdminPaymentEvent {
  final int paymentId;
  final int shipmentId;
  final String? notes;

  const AdminPaymentReconcileRequested({
    required this.paymentId,
    required this.shipmentId,
    this.notes,
  });

  @override
  List<Object?> get props => [paymentId, shipmentId, notes];
}

class AdminPaymentConfirmCodRequested extends AdminPaymentEvent {
  final int paymentId;
  final int shipmentId;
  final num verifiedAmount;
  final String? settlementReference;
  final String? notes;

  const AdminPaymentConfirmCodRequested({
    required this.paymentId,
    required this.shipmentId,
    required this.verifiedAmount,
    this.settlementReference,
    this.notes,
  });

  @override
  List<Object?> get props => [
        paymentId,
        shipmentId,
        verifiedAmount,
        settlementReference,
        notes,
      ];
}

class AdminPaymentClearNotification extends AdminPaymentEvent {
  const AdminPaymentClearNotification();
}

