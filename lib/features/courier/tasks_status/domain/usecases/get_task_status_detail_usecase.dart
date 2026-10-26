import '../entities/task_status_detail.dart';
import '../repositories/courier_task_status_repository.dart';

class GetTaskStatusDetailUseCase {
  final CourierTaskStatusRepository repository;

  const GetTaskStatusDetailUseCase(this.repository);

  Future<TaskStatusDetail> execute(String shipmentId, {String? courierId}) {
    return repository.getTaskStatusDetail(shipmentId, courierId: courierId);
  }

  Future<TaskStatusDetail> call(String shipmentId, {String? courierId}) {
    return execute(shipmentId, courierId: courierId);
  }
}
