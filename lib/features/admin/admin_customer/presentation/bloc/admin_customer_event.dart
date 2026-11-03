import 'package:equatable/equatable.dart';

abstract class AdminCustomerEvent extends Equatable {
  const AdminCustomerEvent();

  @override
  List<Object?> get props => [];
}

class AdminCustomerStarted extends AdminCustomerEvent {
  const AdminCustomerStarted();
}

class AdminCustomerRefreshed extends AdminCustomerEvent {
  const AdminCustomerRefreshed();
}

class AdminCustomerRealtimeTriggered extends AdminCustomerEvent {
  const AdminCustomerRealtimeTriggered();
}

class AdminCustomerSearchChanged extends AdminCustomerEvent {
  final String query;

  const AdminCustomerSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class AdminCustomerFiltersUpdated extends AdminCustomerEvent {
  final String? verificationFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool clearDates;

  const AdminCustomerFiltersUpdated({
    this.verificationFilter,
    this.startDate,
    this.endDate,
    this.clearDates = false,
  });

  @override
  List<Object?> get props => [
        verificationFilter,
        startDate,
        endDate,
        clearDates,
      ];
}

class AdminCustomerFiltersReset extends AdminCustomerEvent {
  const AdminCustomerFiltersReset();
}

class AdminCustomerSortChanged extends AdminCustomerEvent {
  final String sortColumn;

  const AdminCustomerSortChanged(this.sortColumn);

  @override
  List<Object?> get props => [sortColumn];
}

class AdminCustomerPageChanged extends AdminCustomerEvent {
  final int page;

  const AdminCustomerPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class AdminCustomerDetailRequested extends AdminCustomerEvent {
  final int customerId;

  const AdminCustomerDetailRequested(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class AdminCustomerDetailDismissed extends AdminCustomerEvent {
  const AdminCustomerDetailDismissed();
}

class AdminCustomerUpdateRequested extends AdminCustomerEvent {
  final int customerId;
  final String namaLengkap;
  final String email;
  final String noHp;
  final String? alamatLengkap;
  final String? idProvinsi;
  final String? idKabkot;
  final String? idKecamatan;
  final String? idKelurahan;
  final double? latitude;
  final double? longitude;
  final bool emailVerified;

  const AdminCustomerUpdateRequested({
    required this.customerId,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    this.alamatLengkap,
    this.idProvinsi,
    this.idKabkot,
    this.idKecamatan,
    this.idKelurahan,
    this.latitude,
    this.longitude,
    required this.emailVerified,
  });

  @override
  List<Object?> get props => [
        customerId,
        namaLengkap,
        email,
        noHp,
        alamatLengkap,
        idProvinsi,
        idKabkot,
        idKecamatan,
        idKelurahan,
        latitude,
        longitude,
        emailVerified,
      ];
}

class AdminCustomerToggleVerificationRequested extends AdminCustomerEvent {
  final int customerId;
  final bool emailVerified;

  const AdminCustomerToggleVerificationRequested({
    required this.customerId,
    required this.emailVerified,
  });

  @override
  List<Object?> get props => [customerId, emailVerified];
}

class AdminCustomerClearNotification extends AdminCustomerEvent {
  const AdminCustomerClearNotification();
}

