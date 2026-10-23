import '../entities/courier_task.dart';

/// Kontrak repositori domain untuk manajemen tugas kurir
abstract class CourierTasksRepository {
  /// Mengambil daftar tugas kurir terpaginasi dengan filter kelompok, tipe, dan pencarian
  Future<List<CourierTask>> getTasks({
    String? courierId,
    CourierTaskType? type,
    CourierTaskGroup? group,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  });

  /// Memperbarui status alur tugas kurir dan mencatatnya ke pelacakan pengiriman
  Future<CourierTask> updateTaskStatus({
    required String taskId,
    required String shipmentId,
    required String newStatusCode,
    String? notes,
    double? latitude,
    double? longitude,
  });

  /// Mendengarkan perubahan data penugasan atau status pengiriman secara real-time
  Stream<List<CourierTask>> streamTasks({String? courierId});

  /// Mengambil rekap jumlah tugas berdasarkan kelompok status (pending, inProgress, completed)
  Future<Map<CourierTaskGroup, int>> getTaskCounts({String? courierId});
}
