import '../repositories/admin_courier_repository.dart';

class ToggleCourierStatusUseCase {
  final AdminCourierRepository repository;

  const ToggleCourierStatusUseCase(this.repository);

  Future<void> call({
    required int courierId,
    required bool isActive,
  }) {
    return repository.toggleCourierAccountStatus(
      courierId: courierId,
      isActive: isActive,
    );
  }
}

