import '../entities/task_status_detail.dart';
import '../repositories/courier_task_status_repository.dart';

class SubscribeTaskStatusRealtimeUseCase {
  final CourierTaskStatusRepository repository;

  SubscribeTaskStatusRealtimeUseCase(this.repository);

  Stream<TaskStatusDetail> call(String shipmentId) {
    return repository.subscribeToTaskRealtime(shipmentId);
  }
}
