import 'package:equatable/equatable.dart';

abstract class AdminDeliveryEvent extends Equatable {
  const AdminDeliveryEvent();

  @override
  List<Object?> get props => [];
}

class AdminDeliveryStarted extends AdminDeliveryEvent {
  const AdminDeliveryStarted();
}

class AdminDeliveryRefreshed extends AdminDeliveryEvent {
  const AdminDeliveryRefreshed();
}

class AdminDeliveryRealtimeUpdated extends AdminDeliveryEvent {
  const AdminDeliveryRealtimeUpdated();
}

class AdminDeliveryTabChanged extends AdminDeliveryEvent {
  final String tabCategory;

  const AdminDeliveryTabChanged(this.tabCategory);

  @override
  List<Object?> get props => [tabCategory];
}

class AdminDeliverySearchChanged extends AdminDeliveryEvent {
  final String query;

  const AdminDeliverySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class AdminDeliveryFiltersUpdated extends AdminDeliveryEvent {
  final String? statusFilter;
  final String? paymentMethodFilter;
  final String? paymentStatusFilter;
  final String? serviceFilter;
  final String? courierFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool clearDates;

  const AdminDeliveryFiltersUpdated({
    this.statusFilter,
    this.paymentMethodFilter,
    this.paymentStatusFilter,
    this.serviceFilter,
    this.courierFilter,
    this.startDate,
    this.endDate,
    this.clearDates = false,
  });

  @override
  List<Object?> get props => [
        statusFilter,
        paymentMethodFilter,
        paymentStatusFilter,
        serviceFilter,
        courierFilter,
        startDate,
        endDate,
        clearDates,
      ];
}

class AdminDeliveryFiltersReset extends AdminDeliveryEvent {
  const AdminDeliveryFiltersReset();
}

class AdminDeliverySortChanged extends AdminDeliveryEvent {
  final String sortColumn;

  const AdminDeliverySortChanged(this.sortColumn);

  @override
  List<Object?> get props => [sortColumn];
}

class AdminDeliveryPageChanged extends AdminDeliveryEvent {
  final int page;

  const AdminDeliveryPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class AdminDeliveryDetailRequested extends AdminDeliveryEvent {
  final int shipmentId;

  const AdminDeliveryDetailRequested(this.shipmentId);

  @override
  List<Object?> get props => [shipmentId];
}

class AdminDeliveryDetailDismissed extends AdminDeliveryEvent {
  const AdminDeliveryDetailDismissed();
}

class AdminDeliveryConfirmOrderRequested extends AdminDeliveryEvent {
  final int shipmentId;
  final String? notes;

  const AdminDeliveryConfirmOrderRequested({
    required this.shipmentId,
    this.notes,
  });

  @override
  List<Object?> get props => [shipmentId, notes];
}

class AdminDeliveryAssignCourierRequested extends AdminDeliveryEvent {
  final int shipmentId;
  final int courierId;
  final String? notes;

  const AdminDeliveryAssignCourierRequested({
    required this.shipmentId,
    required this.courierId,
    this.notes,
  });

  @override
  List<Object?> get props => [shipmentId, courierId, notes];
}

class AdminDeliveryUpdateStatusRequested extends AdminDeliveryEvent {
  final int shipmentId;
  final String targetStatusCode;
  final String? lokasiNama;
  final String? notes;

  const AdminDeliveryUpdateStatusRequested({
    required this.shipmentId,
    required this.targetStatusCode,
    this.lokasiNama,
    this.notes,
  });

  @override
  List<Object?> get props => [shipmentId, targetStatusCode, lokasiNama, notes];
}

class AdminDeliveryHandleFailedRequested extends AdminDeliveryEvent {
  final int shipmentId;
  final String resolutionAction;
  final int? reassignCourierId;
  final String? notes;

  const AdminDeliveryHandleFailedRequested({
    required this.shipmentId,
    required this.resolutionAction,
    this.reassignCourierId,
    this.notes,
  });

  @override
  List<Object?> get props => [
        shipmentId,
        resolutionAction,
        reassignCourierId,
        notes,
      ];
}

class AdminDeliveryClearNotification extends AdminDeliveryEvent {
  const AdminDeliveryClearNotification();
}

