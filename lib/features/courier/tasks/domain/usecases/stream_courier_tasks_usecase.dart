import '../entities/courier_task.dart';
import '../repositories/courier_tasks_repository.dart';

/// Use case untuk berlangganan pembaruan tugas kurir secara real-time
class StreamCourierTasksUseCase {
  final CourierTasksRepository repository;

  StreamCourierTasksUseCase(this.repository);

  Stream<List<CourierTask>> call({String? courierId}) {
    return repository.streamTasks(courierId: courierId);
  }
}
