import '../entities/courier_task_history_stats.dart';
import '../repositories/courier_tasks_history_repository.dart';

/// Use case untuk memuat data rekapitulasi statistik tugas riwayat kurir
class GetCourierTaskHistoryStatsUseCase {
  final CourierTasksHistoryRepository repository;

  GetCourierTaskHistoryStatsUseCase(this.repository);

  Future<CourierTaskHistoryStats> call({String? courierId}) {
    return repository.getHistoryStats(courierId: courierId);
  }
}
