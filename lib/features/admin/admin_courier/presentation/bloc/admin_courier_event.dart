import 'package:equatable/equatable.dart';

abstract class AdminCourierEvent extends Equatable {
  const AdminCourierEvent();

  @override
  List<Object?> get props => [];
}

class AdminCourierStarted extends AdminCourierEvent {
  const AdminCourierStarted();
}

class AdminCourierRefreshed extends AdminCourierEvent {
  const AdminCourierRefreshed();
}

class AdminCourierRealtimeTriggered extends AdminCourierEvent {
  const AdminCourierRealtimeTriggered();
}

class AdminCourierSearchChanged extends AdminCourierEvent {
  final String query;

  const AdminCourierSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class AdminCourierFiltersUpdated extends AdminCourierEvent {
  final String? accountStatusFilter;
  final String? activityStatusFilter;

  const AdminCourierFiltersUpdated({
    this.accountStatusFilter,
    this.activityStatusFilter,
  });

  @override
  List<Object?> get props => [accountStatusFilter, activityStatusFilter];
}

class AdminCourierFiltersReset extends AdminCourierEvent {
  const AdminCourierFiltersReset();
}

class AdminCourierSortChanged extends AdminCourierEvent {
  final String sortColumn;

  const AdminCourierSortChanged(this.sortColumn);

  @override
  List<Object?> get props => [sortColumn];
}

class AdminCourierPageChanged extends AdminCourierEvent {
  final int page;

  const AdminCourierPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class AdminCourierDetailRequested extends AdminCourierEvent {
  final int courierId;

  const AdminCourierDetailRequested(this.courierId);

  @override
  List<Object?> get props => [courierId];
}

class AdminCourierDetailDismissed extends AdminCourierEvent {
  const AdminCourierDetailDismissed();
}

class AdminCourierCreateRequested extends AdminCourierEvent {
  final String namaLengkap;
  final String email;
  final String noHp;
  final String password;
  final String? employeeCode;
  final String? alamatLengkap;
  final String? fotoUrl;
  final bool isActive;

  const AdminCourierCreateRequested({
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    required this.password,
    this.employeeCode,
    this.alamatLengkap,
    this.fotoUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        namaLengkap,
        email,
        noHp,
        password,
        employeeCode,
        alamatLengkap,
        fotoUrl,
        isActive,
      ];
}

class AdminCourierUpdateRequested extends AdminCourierEvent {
  final int courierId;
  final String namaLengkap;
  final String email;
  final String noHp;
  final String? alamatLengkap;
  final String? fotoUrl;
  final String? newPassword;
  final bool isActive;

  const AdminCourierUpdateRequested({
    required this.courierId,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    this.alamatLengkap,
    this.fotoUrl,
    this.newPassword,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        courierId,
        namaLengkap,
        email,
        noHp,
        alamatLengkap,
        fotoUrl,
        newPassword,
        isActive,
      ];
}

class AdminCourierToggleStatusRequested extends AdminCourierEvent {
  final int courierId;
  final bool isActive;

  const AdminCourierToggleStatusRequested({
    required this.courierId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [courierId, isActive];
}

class AdminCourierUnassignTaskRequested extends AdminCourierEvent {
  final int assignmentId;
  final int shipmentId;
  final String? reason;

  const AdminCourierUnassignTaskRequested({
    required this.assignmentId,
    required this.shipmentId,
    this.reason,
  });

  @override
  List<Object?> get props => [assignmentId, shipmentId, reason];
}

class AdminCourierClearNotification extends AdminCourierEvent {
  const AdminCourierClearNotification();
}

