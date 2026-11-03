import '../entities/admin_settings_data.dart';
import '../repositories/admin_settings_repository.dart';

class GetAdminSettingsUseCase {
  final AdminSettingsRepository repository;

  const GetAdminSettingsUseCase(this.repository);

  Future<AdminSettingsData> call() {
    return repository.getSettingsData();
  }
}

