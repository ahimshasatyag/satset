import '../repositories/admin_service_type_repository.dart';

class DeleteServiceTypeUseCase {
  final AdminServiceTypeRepository repository;

  const DeleteServiceTypeUseCase(this.repository);

  Future<void> call(int serviceId) {
    return repository.deleteServiceType(serviceId);
  }
}

