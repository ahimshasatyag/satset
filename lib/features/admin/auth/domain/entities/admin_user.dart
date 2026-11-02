import 'package:equatable/equatable.dart';
import 'package:satset/features/auth/domain/entities/user.dart';

/// Entity bisnis untuk pengguna tingkat Administrator SatSet Delivery
class AdminUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final int idUsersRole;
  final String? employeeCode;
  final String? employeeType;
  final String? photoUrl;
  final String? token;
  final bool isActive;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'admin',
    this.idUsersRole = 1,
    this.employeeCode,
    this.employeeType = 'ADMIN',
    this.photoUrl,
    this.token,
    this.isActive = true,
    this.createdAt,
  });

  /// Mengonversi [AdminUser] ke objek [User] standar agar kompatibel
  /// dengan seluruh modul dashboard, riwayat, dan profil SatSet
  User toUser() {
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
      token: token,
      role: 'admin',
      idUsersRole: idUsersRole,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        idUsersRole,
        employeeCode,
        employeeType,
        photoUrl,
        token,
        isActive,
        createdAt,
      ];
}

