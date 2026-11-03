import '../repositories/admin_settings_repository.dart';

class ChangeAdminPasswordUseCase {
  final AdminSettingsRepository repository;

  const ChangeAdminPasswordUseCase(this.repository);

  Future<void> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (newPassword.length < 6) {
      throw Exception('Kata sandi baru minimal harus terdiri dari 6 karakter.');
    }
    if (newPassword != confirmPassword) {
      throw Exception('Konfirmasi kata sandi baru tidak cocok.');
    }
    if (currentPassword == newPassword) {
      throw Exception(
        'Kata sandi baru harus berbeda dari kata sandi saat ini.',
      );
    }

    return repository.changeAdminPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

