import '../entities/task_status_step.dart';
import '../repositories/courier_task_status_repository.dart';

class GetTaskTimelineUseCase {
  final CourierTaskStatusRepository repository;

  const GetTaskTimelineUseCase(this.repository);

  Future<List<TaskStatusStep>> execute(String shipmentId) {
    return repository.getTaskTimeline(shipmentId);
  }

  Future<List<TaskStatusStep>> call(String shipmentId) {
    return execute(shipmentId);
  }
}
