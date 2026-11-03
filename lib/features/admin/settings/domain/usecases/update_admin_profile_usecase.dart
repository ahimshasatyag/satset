import '../entities/admin_profile.dart';
import '../repositories/admin_settings_repository.dart';

class UpdateAdminProfileUseCase {
  final AdminSettingsRepository repository;

  const UpdateAdminProfileUseCase(this.repository);

  Future<AdminProfile> call({
    required int adminId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
  }) {
    if (namaLengkap.trim().isEmpty) {
      throw Exception('Nama lengkap administrator tidak boleh kosong.');
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Alamat email tidak valid.');
    }
    if (noHp.trim().isEmpty) {
      throw Exception('Nomor telepon / HP tidak boleh kosong.');
    }

    return repository.updateAdminProfile(
      adminId: adminId,
      namaLengkap: namaLengkap.trim(),
      email: email.trim(),
      noHp: noHp.trim(),
      alamatLengkap: alamatLengkap?.trim(),
    );
  }
}

