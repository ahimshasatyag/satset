import '../entities/courier_task_history_detail.dart';
import '../entities/courier_task_history_item.dart';
import '../entities/courier_task_history_stats.dart';

/// Kontrak repositori domain untuk riwayat tugas kurir
abstract class CourierTasksHistoryRepository {
  /// Mengambil daftar riwayat tugas kurir terpaginasi dengan berbagai parameter filter
  Future<List<CourierTaskHistoryItem>> getHistoryTasks({
    String? courierId,
    CourierHistoryTaskType? taskType,
    String? statusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });

  /// Mengambil detail lengkap tugas pengiriman beserta kronologi jejak dan bukti serah terima
  Future<CourierTaskHistoryDetail> getHistoryDetail({
    required String shipmentId,
    required String taskId,
    String? courierId,
  });

  /// Mengambil ringkasan statistik riwayat tugas kurir
  Future<CourierTaskHistoryStats> getHistoryStats({String? courierId});
}
