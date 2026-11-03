import '../../domain/entities/admin_assignable_courier.dart';

class AdminAssignableCourierModel extends AdminAssignableCourier {
  const AdminAssignableCourierModel({
    required super.id,
    required super.employeeCode,
    required super.namaLengkap,
    required super.email,
    required super.noHp,
    super.alamatLengkap,
    super.fotoUrl,
    required super.isActive,
    super.idUsersRole = 2,
    super.activeAssignmentsCount = 0,
    super.completedAssignmentsCount = 0,
  });

  factory AdminAssignableCourierModel.fromMap(
    Map<String, dynamic> map, {
    int activeAssignmentsCount = 0,
    int completedAssignmentsCount = 0,
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final roleId = int.tryParse(map['id_users_role']?.toString() ?? '2') ?? 2;
    final isActive = map['is_active'] == null ||
        map['is_active'] == true ||
        map['is_active'] == 1;

    return AdminAssignableCourierModel(
      id: id,
      employeeCode: (map['employee_code'] ?? 'KUR-$id').toString(),
      namaLengkap: (map['nama_lengkap'] ?? 'Kurir SatSet').toString(),
      email: (map['email'] ?? '-').toString(),
      noHp: (map['no_hp'] ?? '-').toString(),
      alamatLengkap: map['alamat_lengkap']?.toString(),
      fotoUrl: map['foto_url']?.toString(),
      isActive: isActive,
      idUsersRole: roleId,
      activeAssignmentsCount: activeAssignmentsCount,
      completedAssignmentsCount: completedAssignmentsCount,
    );
  }
}

