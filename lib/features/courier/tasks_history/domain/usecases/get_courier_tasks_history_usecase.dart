import 'package:equatable/equatable.dart';
import '../entities/courier_task_history_item.dart';
import '../repositories/courier_tasks_history_repository.dart';

/// Parameter input untuk pemuatan riwayat tugas kurir
class GetCourierTasksHistoryParams extends Equatable {
  final String? courierId;
  final CourierHistoryTaskType? taskType;
  final String? statusCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final int page;
  final int limit;

  const GetCourierTasksHistoryParams({
    this.courierId,
    this.taskType,
    this.statusCode,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
        courierId,
        taskType,
        statusCode,
        startDate,
        endDate,
        searchQuery,
        page,
        limit,
      ];
}

/// Use case untuk memuat daftar riwayat tugas kurir terpaginasi
class GetCourierTasksHistoryUseCase {
  final CourierTasksHistoryRepository repository;

  GetCourierTasksHistoryUseCase(this.repository);

  Future<List<CourierTaskHistoryItem>> call(
      GetCourierTasksHistoryParams params) {
    return repository.getHistoryTasks(
      courierId: params.courierId,
      taskType: params.taskType,
      statusCode: params.statusCode,
      startDate: params.startDate,
      endDate: params.endDate,
      searchQuery: params.searchQuery,
      page: params.page,
      limit: params.limit,
    );
  }
}
