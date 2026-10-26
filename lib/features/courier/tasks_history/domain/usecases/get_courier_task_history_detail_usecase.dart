import '../entities/courier_task_history_detail.dart';
import '../repositories/courier_tasks_history_repository.dart';

/// Use case untuk memuat detail riwayat tugas termasuk jejak tracking dan bukti pengiriman
class GetCourierTaskHistoryDetailUseCase {
  final CourierTasksHistoryRepository repository;

  GetCourierTaskHistoryDetailUseCase(this.repository);

  Future<CourierTaskHistoryDetail> call({
    required String shipmentId,
    required String taskId,
    String? courierId,
  }) {
    return repository.getHistoryDetail(
      shipmentId: shipmentId,
      taskId: taskId,
      courierId: courierId,
    );
  }
}
