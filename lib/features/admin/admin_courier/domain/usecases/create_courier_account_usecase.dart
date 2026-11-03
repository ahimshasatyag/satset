import '../entities/admin_courier_item.dart';
import '../repositories/admin_courier_repository.dart';

class CreateCourierAccountUseCase {
  final AdminCourierRepository repository;

  const CreateCourierAccountUseCase(this.repository);

  Future<AdminCourierItem> call({
    required String namaLengkap,
    required String email,
    required String noHp,
    required String password,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
    bool isActive = true,
  }) {
    return repository.createCourierAccount(
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      password: password,
      employeeCode: employeeCode,
      alamatLengkap: alamatLengkap,
      fotoUrl: fotoUrl,
      isActive: isActive,
    );
  }
}

