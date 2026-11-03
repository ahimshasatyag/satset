import '../../domain/entities/admin_profile.dart';

class AdminProfileModel extends AdminProfile {
  const AdminProfileModel({
    required super.id,
    required super.employeeCode,
    required super.namaLengkap,
    required super.email,
    required super.noHp,
    super.alamatLengkap,
    super.idUsersRole,
    super.role,
    super.employeeType,
    super.photoUrl,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory AdminProfileModel.fromMap(Map<String, dynamic> map) {
    return AdminProfileModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      employeeCode: map['employee_code']?.toString() ?? 'ADM-01',
      namaLengkap: (map['nama_lengkap'] ?? map['nama'] ?? 'Administrator')
          .toString(),
      email: map['email']?.toString() ?? '',
      noHp: (map['no_hp'] ?? map['telepon'] ?? '').toString(),
      alamatLengkap: map['alamat_lengkap']?.toString(),
      idUsersRole: int.tryParse(map['id_users_role']?.toString() ?? '1') ?? 1,
      role: map['role']?.toString() ?? 'admin',
      employeeType: map['employee_type']?.toString() ?? 'ADMIN',
      photoUrl: map['foto_url']?.toString(),
      isActive: map['is_active'] != false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_hp': noHp,
      if (alamatLengkap != null) 'alamat_lengkap': alamatLengkap,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

