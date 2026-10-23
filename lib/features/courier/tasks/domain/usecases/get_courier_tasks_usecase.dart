import '../entities/courier_task.dart';
import '../repositories/courier_tasks_repository.dart';

/// Use case untuk memuat daftar tugas kurir dengan filter dan pencarian
class GetCourierTasksUseCase {
  final CourierTasksRepository repository;

  GetCourierTasksUseCase(this.repository);

  Future<List<CourierTask>> call({
    String? courierId,
    CourierTaskType? type,
    CourierTaskGroup? group,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) {
    return repository.getTasks(
      courierId: courierId,
      type: type,
      group: group,
      searchQuery: searchQuery,
      page: page,
      limit: limit,
    );
  }
}
