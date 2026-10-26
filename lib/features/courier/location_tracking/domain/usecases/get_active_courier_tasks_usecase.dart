import '../entities/courier_tracking_task.dart';
import '../repositories/courier_location_tracking_repository.dart';

/// Use case untuk memuat daftar tugas aktif yang sedang dijalankan kurir
class GetActiveCourierTasksUseCase {
  final CourierLocationTrackingRepository repository;

  GetActiveCourierTasksUseCase(this.repository);

  Future<List<CourierTrackingTask>> call({String? courierId}) {
    return repository.getActiveCourierTasks(courierId: courierId);
  }
}
