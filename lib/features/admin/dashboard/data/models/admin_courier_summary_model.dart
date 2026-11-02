import '../../domain/entities/admin_courier_summary.dart';

class AdminCourierSummaryModel extends AdminCourierSummary {
  const AdminCourierSummaryModel({
    required super.courierId,
    required super.namaLengkap,
    required super.employeeCode,
    required super.noHp,
    required super.activeAssignmentsCount,
    required super.completedAssignmentsCount,
    super.lastLocationName,
    super.lastLocationUpdate,
    required super.hasActiveDuty,
  });

  factory AdminCourierSummaryModel.fromData({
    required Map<String, dynamic> employeeMap,
    required int activeAssignments,
    required int completedAssignments,
    String? lastLocationName,
    DateTime? lastLocationUpdate,
  }) {
    final id = int.tryParse(employeeMap['id']?.toString() ?? '0') ?? 0;
    final name = employeeMap['nama_lengkap']?.toString() ??
        employeeMap['nama']?.toString() ??
        'Kurir SatSet #$id';
    final code = employeeMap['employee_code']?.toString() ?? 'EXP-$id';
    final phone = employeeMap['no_hp']?.toString() ??
        employeeMap['telepon']?.toString() ??
        '-';

    return AdminCourierSummaryModel(
      courierId: id,
      namaLengkap: name,
      employeeCode: code,
      noHp: phone,
      activeAssignmentsCount: activeAssignments,
      completedAssignmentsCount: completedAssignments,
      lastLocationName: lastLocationName,
      lastLocationUpdate: lastLocationUpdate,
      hasActiveDuty: activeAssignments > 0,
    );
  }
}

