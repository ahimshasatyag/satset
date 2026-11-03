import '../entities/admin_courier_item.dart';
import '../repositories/admin_courier_repository.dart';

class UpdateCourierProfileUseCase {
  final AdminCourierRepository repository;

  const UpdateCourierProfileUseCase(this.repository);

  Future<AdminCourierItem> call({
    required int courierId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? fotoUrl,
    String? newPassword,
    required bool isActive,
  }) {
    return repository.updateCourierProfile(
      courierId: courierId,
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      alamatLengkap: alamatLengkap,
      fotoUrl: fotoUrl,
      newPassword: newPassword,
      isActive: isActive,
    );
  }
}

