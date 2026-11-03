import '../repositories/admin_courier_repository.dart';

class UnassignCourierTaskUseCase {
  final AdminCourierRepository repository;

  const UnassignCourierTaskUseCase(this.repository);

  Future<void> call({
    required int assignmentId,
    required int shipmentId,
    String? reason,
  }) {
    return repository.unassignCourierTask(
      assignmentId: assignmentId,
      shipmentId: shipmentId,
      reason: reason,
    );
  }
}

