import '../entities/courier_task.dart';
import '../repositories/courier_tasks_repository.dart';

/// Use case untuk memperbarui status pelaksanaan tugas kurir
class UpdateTaskStatusUseCase {
  final CourierTasksRepository repository;

  UpdateTaskStatusUseCase(this.repository);

  Future<CourierTask> call({
    required String taskId,
    required String shipmentId,
    required String newStatusCode,
    String? notes,
    double? latitude,
    double? longitude,
  }) {
    return repository.updateTaskStatus(
      taskId: taskId,
      shipmentId: shipmentId,
      newStatusCode: newStatusCode,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
