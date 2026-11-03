import 'package:equatable/equatable.dart';

abstract class AdminServiceTypeEvent extends Equatable {
  const AdminServiceTypeEvent();

  @override
  List<Object?> get props => [];
}

class AdminServiceTypeStarted extends AdminServiceTypeEvent {
  const AdminServiceTypeStarted();
}

class AdminServiceTypeRefreshed extends AdminServiceTypeEvent {
  const AdminServiceTypeRefreshed();
}

class AdminServiceTypeRealtimeUpdated extends AdminServiceTypeEvent {
  const AdminServiceTypeRealtimeUpdated();
}

class AdminServiceTypeSearchChanged extends AdminServiceTypeEvent {
  final String searchQuery;

  const AdminServiceTypeSearchChanged(this.searchQuery);

  @override
  List<Object?> get props => [searchQuery];
}

class AdminServiceTypeFilterChanged extends AdminServiceTypeEvent {
  final String statusFilter;

  const AdminServiceTypeFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

class AdminServiceTypeFiltersReset extends AdminServiceTypeEvent {
  const AdminServiceTypeFiltersReset();
}

class AdminServiceTypeSortChanged extends AdminServiceTypeEvent {
  final String sortColumn;

  const AdminServiceTypeSortChanged(this.sortColumn);

  @override
  List<Object?> get props => [sortColumn];
}

class AdminServiceTypePageChanged extends AdminServiceTypeEvent {
  final int page;

  const AdminServiceTypePageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class AdminServiceTypeDetailRequested extends AdminServiceTypeEvent {
  final int serviceId;

  const AdminServiceTypeDetailRequested(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class AdminServiceTypeDetailDismissed extends AdminServiceTypeEvent {
  const AdminServiceTypeDetailDismissed();
}

class AdminServiceTypeCreateRequested extends AdminServiceTypeEvent {
  final String kode;
  final String namaLayanan;
  final int estimasiHariMin;
  final int estimasiHariMax;
  final String? deskripsi;
  final num? baseTariffPerKg;
  final bool isActive;

  const AdminServiceTypeCreateRequested({
    required this.kode,
    required this.namaLayanan,
    required this.estimasiHariMin,
    required this.estimasiHariMax,
    this.deskripsi,
    this.baseTariffPerKg,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        kode,
        namaLayanan,
        estimasiHariMin,
        estimasiHariMax,
        deskripsi,
        baseTariffPerKg,
        isActive,
      ];
}

class AdminServiceTypeUpdateRequested extends AdminServiceTypeEvent {
  final int serviceId;
  final String kode;
  final String namaLayanan;
  final int estimasiHariMin;
  final int estimasiHariMax;
  final String? deskripsi;
  final num? baseTariffPerKg;
  final bool isActive;

  const AdminServiceTypeUpdateRequested({
    required this.serviceId,
    required this.kode,
    required this.namaLayanan,
    required this.estimasiHariMin,
    required this.estimasiHariMax,
    this.deskripsi,
    this.baseTariffPerKg,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        serviceId,
        kode,
        namaLayanan,
        estimasiHariMin,
        estimasiHariMax,
        deskripsi,
        baseTariffPerKg,
        isActive,
      ];
}

class AdminServiceTypeToggleStatusRequested extends AdminServiceTypeEvent {
  final int serviceId;
  final bool isActive;

  const AdminServiceTypeToggleStatusRequested({
    required this.serviceId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [serviceId, isActive];
}

class AdminServiceTypeDeleteRequested extends AdminServiceTypeEvent {
  final int serviceId;

  const AdminServiceTypeDeleteRequested(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class AdminServiceTypeClearNotification extends AdminServiceTypeEvent {
  const AdminServiceTypeClearNotification();
}

