import 'package:equatable/equatable.dart';

/// Entity ringkasan penugasan dan aktivitas kurir di dashboard admin
class AdminCourierSummary extends Equatable {
  final int courierId;
  final String namaLengkap;
  final String employeeCode;
  final String noHp;
  final int activeAssignmentsCount;
  final int completedAssignmentsCount;
  final String? lastLocationName;
  final DateTime? lastLocationUpdate;
  final bool hasActiveDuty;

  const AdminCourierSummary({
    required this.courierId,
    required this.namaLengkap,
    required this.employeeCode,
    required this.noHp,
    required this.activeAssignmentsCount,
    required this.completedAssignmentsCount,
    this.lastLocationName,
    this.lastLocationUpdate,
    required this.hasActiveDuty,
  });

  @override
  List<Object?> get props => [
        courierId,
        namaLengkap,
        employeeCode,
        noHp,
        activeAssignmentsCount,
        completedAssignmentsCount,
        lastLocationName,
        lastLocationUpdate,
        hasActiveDuty,
      ];
}

