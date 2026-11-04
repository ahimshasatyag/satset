import '../entities/admin_user.dart';
import '../repositories/admin_auth_repository.dart';

class AdminRegisterUseCase {
  final AdminAuthRepository repository;

  AdminRegisterUseCase(this.repository);

  Future<AdminUser> execute({
    required String namaLengkap,
    required String email,
    required String password,
    String? noHp,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
  }) {
    return repository.registerAdmin(
      namaLengkap: namaLengkap,
      email: email,
      password: password,
      noHp: noHp,
      employeeCode: employeeCode,
      alamatLengkap: alamatLengkap,
      fotoUrl: fotoUrl,
    );
  }
}

