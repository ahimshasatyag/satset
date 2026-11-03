import '../repositories/admin_settings_repository.dart';

class ToggleServiceTypeActiveUseCase {
  final AdminSettingsRepository repository;

  const ToggleServiceTypeActiveUseCase(this.repository);

  Future<void> call({
    required int serviceTypeId,
    required bool isActive,
  }) {
    return repository.toggleServiceTypeStatus(
      serviceTypeId: serviceTypeId,
      isActive: isActive,
    );
  }
}

