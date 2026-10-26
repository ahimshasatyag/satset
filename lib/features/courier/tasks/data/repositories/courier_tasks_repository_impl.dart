import '../../domain/entities/courier_task.dart';
import '../../domain/repositories/courier_tasks_repository.dart';
import '../datasources/courier_tasks_local_datasource.dart';
import '../datasources/courier_tasks_remote_datasource.dart';

/// Implementasi Clean Architecture repositori tugas kurir
class CourierTasksRepositoryImpl implements CourierTasksRepository {
  final CourierTasksRemoteDataSource remoteDataSource;
  final CourierTasksLocalDataSource localDataSource;

  CourierTasksRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<CourierTask>> getTasks({
    String? courierId,
    CourierTaskType? type,
    CourierTaskGroup? group,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final remoteTasks = await remoteDataSource.getTasks(
        courierId: courierId,
        type: type,
        group: group,
        searchQuery: searchQuery,
        page: page,
        limit: limit,
      );

      // Simpan ke cache lokal hanya jika halaman pertama tanpa filter query
      if (page == 1 && (searchQuery == null || searchQuery.isEmpty)) {
        await localDataSource.cacheTasks(remoteTasks);
      }

      return remoteTasks;
    } catch (_) {
      // Offline fallback dari cache lokal
      final cached = await localDataSource.getCachedTasks();
      var filtered = cached;
      if (type != null) {
        filtered = filtered.where((t) => t.taskType == type).toList();
      }
      if (group != null) {
        filtered = filtered.where((t) => t.taskGroup == group).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        filtered = filtered.where((t) {
          return t.trackingNumber.toLowerCase().contains(q) ||
              t.receiverName.toLowerCase().contains(q) ||
              t.senderName.toLowerCase().contains(q);
        }).toList();
      }
      return filtered;
    }
  }

  @override
  Future<CourierTask> updateTaskStatus({
    required String taskId,
    required String shipmentId,
    required String newStatusCode,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final updated = await remoteDataSource.updateTaskStatus(
      taskId: taskId,
      shipmentId: shipmentId,
      newStatusCode: newStatusCode,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
    );

    // Perbarui entri pada cache lokal
    try {
      final cached = await localDataSource.getCachedTasks();
      final updatedList = cached.map((t) {
        if (t.id == taskId) {
          return updated;
        }
        return t;
      }).toList();
      await localDataSource.cacheTasks(updatedList);
    } catch (_) {}

    return updated;
  }

  @override
  Stream<List<CourierTask>> streamTasks({String? courierId}) {
    return remoteDataSource.streamTasks(courierId: courierId).map((models) {
      if (models.isNotEmpty) {
        localDataSource.cacheTasks(models);
      }
      return models;
    });
  }

  @override
  Future<Map<CourierTaskGroup, int>> getTaskCounts({String? courierId}) async {
    try {
      return await remoteDataSource.getTaskCounts(courierId: courierId);
    } catch (_) {
      final cached = await localDataSource.getCachedTasks();
      int pending = 0;
      int inProgress = 0;
      int completed = 0;

      for (final t in cached) {
        switch (t.taskGroup) {
          case CourierTaskGroup.pending:
            pending++;
            break;
          case CourierTaskGroup.inProgress:
            inProgress++;
            break;
          case CourierTaskGroup.completed:
            completed++;
            break;
        }
      }

      return {
        CourierTaskGroup.pending: pending,
        CourierTaskGroup.inProgress: inProgress,
        CourierTaskGroup.completed: completed,
      };
    }
  }
}
