import '../repositories/courier_task_status_repository.dart';

class UpdateCourierTaskStatusUseCase {
  final CourierTaskStatusRepository repository;

  UpdateCourierTaskStatusUseCase(this.repository);

  Future<void> call({
    required String shipmentId,
    required String courierId,
    required int targetStatusId,
    required String targetStatusCode,
    String? notes,
    String? failureReason,
    String? locationName,
    double? latitude,
    double? longitude,
  }) {
    return repository.updateTaskStatus(
      shipmentId: shipmentId,
      courierId: courierId,
      targetStatusId: targetStatusId,
      targetStatusCode: targetStatusCode,
      notes: notes,
      failureReason: failureReason,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
