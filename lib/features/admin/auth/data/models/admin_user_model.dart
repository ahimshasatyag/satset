import '../../domain/entities/admin_user.dart';

class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.role = 'admin',
    super.idUsersRole = 1,
    super.employeeCode,
    super.employeeType = 'ADMIN',
    super.photoUrl,
    super.token,
    super.isActive = true,
    super.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    final roleId = int.tryParse(json['id_users_role']?.toString() ?? '1') ?? 1;

    return AdminUserModel(
      id: (json['id'] ?? '').toString(),
      name: (json['nama_lengkap'] ?? json['name'] ?? json['nama'] ?? 'Administrator').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['no_hp'] ?? json['phone'] ?? '').toString(),
      role: 'admin',
      idUsersRole: roleId,
      employeeCode: json['employee_code']?.toString(),
      employeeType: json['employee_type']?.toString() ?? 'ADMIN',
      photoUrl: json['foto_url']?.toString() ?? json['photo_url']?.toString(),
      token: token ?? json['token']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': name,
      'email': email,
      'no_hp': phone,
      'role': role,
      'id_users_role': idUsersRole,
      'employee_code': employeeCode,
      'employee_type': employeeType,
      'foto_url': photoUrl,
      'token': token,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

