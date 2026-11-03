import '../repositories/admin_service_type_repository.dart';

class ToggleServiceTypeStatusUseCase {
  final AdminServiceTypeRepository repository;

  const ToggleServiceTypeStatusUseCase(this.repository);

  Future<void> call({
    required int serviceId,
    required bool isActive,
  }) {
    return repository.toggleServiceTypeStatus(
      serviceId: serviceId,
      isActive: isActive,
    );
  }
}

