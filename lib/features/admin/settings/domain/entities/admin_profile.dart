import 'package:equatable/equatable.dart';

class AdminProfile extends Equatable {
  final int id;
  final String employeeCode;
  final String namaLengkap;
  final String email;
  final String noHp;
  final String? alamatLengkap;
  final int idUsersRole;
  final String role;
  final String employeeType;
  final String? photoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminProfile({
    required this.id,
    required this.employeeCode,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    this.alamatLengkap,
    this.idUsersRole = 1,
    this.role = 'admin',
    this.employeeType = 'ADMIN',
    this.photoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  AdminProfile copyWith({
    int? id,
    String? employeeCode,
    String? namaLengkap,
    String? email,
    String? noHp,
    String? alamatLengkap,
    int? idUsersRole,
    String? role,
    String? employeeType,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminProfile(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      idUsersRole: idUsersRole ?? this.idUsersRole,
      role: role ?? this.role,
      employeeType: employeeType ?? this.employeeType,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeCode,
        namaLengkap,
        email,
        noHp,
        alamatLengkap,
        idUsersRole,
        role,
        employeeType,
        photoUrl,
        isActive,
        createdAt,
        updatedAt,
      ];
}

