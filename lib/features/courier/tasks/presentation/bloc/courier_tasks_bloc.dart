import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/courier_task.dart';
import '../../domain/usecases/get_courier_tasks_usecase.dart';
import '../../domain/usecases/stream_courier_tasks_usecase.dart';
import '../../domain/usecases/update_task_status_usecase.dart';
import 'courier_tasks_event.dart';
import 'courier_tasks_state.dart';

class CourierTasksBloc extends Bloc<CourierTasksEvent, CourierTasksState> {
  final GetCourierTasksUseCase getCourierTasksUseCase;
  final UpdateTaskStatusUseCase updateTaskStatusUseCase;
  final StreamCourierTasksUseCase streamCourierTasksUseCase;

  StreamSubscription<List<CourierTask>>? _realtimeSubscription;

  CourierTasksBloc({
    required this.getCourierTasksUseCase,
    required this.updateTaskStatusUseCase,
    required this.streamCourierTasksUseCase,
  }) : super(const CourierTasksState()) {
    on<CourierTasksFetched>(_onFetched);
    on<CourierTasksLoadMore>(_onLoadMore);
    on<CourierTasksSearchChanged>(_onSearchChanged);
    on<CourierTasksGroupChanged>(_onGroupChanged);
    on<CourierTasksTypeFilterChanged>(_onTypeFilterChanged);
    on<CourierTaskStatusUpdated>(_onStatusUpdated);
    on<CourierTasksRealtimeReceived>(_onRealtimeReceived);
    on<CourierTasksSubscriptionStarted>(_onSubscriptionStarted);
  }

  void _onSubscriptionStarted(
    CourierTasksSubscriptionStarted event,
    Emitter<CourierTasksState> emit,
  ) {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = streamCourierTasksUseCase().listen(
      (tasks) => add(CourierTasksRealtimeReceived(tasks)),
      onError: (_) {},
    );
  }

  Future<void> _onFetched(
    CourierTasksFetched event,
    Emitter<CourierTasksState> emit,
  ) async {
    if (event.isRefresh) {
      emit(state.copyWith(
        status: CourierTasksStatus.loading,
        errorMessage: null,
      ));
    } else if (state.status == CourierTasksStatus.initial) {
      emit(state.copyWith(status: CourierTasksStatus.loading));
    }

    try {
      final tasks = await getCourierTasksUseCase(
        page: 1,
        limit: 30,
        searchQuery: state.searchQuery,
      );

      final counts = _calculateCounts(tasks);

      emit(state.copyWith(
        status: CourierTasksStatus.success,
        tasks: tasks,
        page: 1,
        hasReachedMax: tasks.length < 30,
        counts: counts,
        lastUpdatedAt: DateTime.now(),
        errorMessage: null,
        isOffline: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CourierTasksStatus.failure,
        errorMessage: 'Gagal memuat tugas kurir. Periksa koneksi internet Anda.',
        isOffline: true,
      ));
    }
  }

  Future<void> _onLoadMore(
    CourierTasksLoadMore event,
    Emitter<CourierTasksState> emit,
  ) async {
    if (state.hasReachedMax || state.status == CourierTasksStatus.loading) return;

    try {
      final nextPage = state.page + 1;
      final moreTasks = await getCourierTasksUseCase(
        page: nextPage,
        limit: 20,
        searchQuery: state.searchQuery,
      );

      if (moreTasks.isEmpty) {
        emit(state.copyWith(hasReachedMax: true));
      } else {
        final combined = [...state.tasks, ...moreTasks];
        final counts = _calculateCounts(combined);

        emit(state.copyWith(
          tasks: combined,
          page: nextPage,
          hasReachedMax: moreTasks.length < 20,
          counts: counts,
          lastUpdatedAt: DateTime.now(),
        ));
      }
    } catch (_) {}
  }

  void _onSearchChanged(
    CourierTasksSearchChanged event,
    Emitter<CourierTasksState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onGroupChanged(
    CourierTasksGroupChanged event,
    Emitter<CourierTasksState> emit,
  ) {
    emit(state.copyWith(selectedGroup: event.group));
  }

  void _onTypeFilterChanged(
    CourierTasksTypeFilterChanged event,
    Emitter<CourierTasksState> emit,
  ) {
    if (event.type == null) {
      emit(state.copyWith(clearTypeFilter: true));
    } else {
      emit(state.copyWith(selectedType: event.type));
    }
  }

  Future<void> _onStatusUpdated(
    CourierTaskStatusUpdated event,
    Emitter<CourierTasksState> emit,
  ) async {
    emit(state.copyWith(
      status: CourierTasksStatus.updating,
      errorMessage: null,
      successMessage: null,
    ));

    try {
      final updated = await updateTaskStatusUseCase(
        taskId: event.taskId,
        shipmentId: event.shipmentId,
        newStatusCode: event.newStatusCode,
        notes: event.notes,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      final updatedTasks = state.tasks.map((task) {
        if (task.id == event.taskId || task.shipmentId == event.shipmentId) {
          return updated;
        }
        return task;
      }).toList();

      final counts = _calculateCounts(updatedTasks);

      emit(state.copyWith(
        status: CourierTasksStatus.success,
        tasks: updatedTasks,
        counts: counts,
        lastUpdatedAt: DateTime.now(),
        successMessage: 'Status tugas berhasil diperbarui menjadi ${updated.statusName}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CourierTasksStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onRealtimeReceived(
    CourierTasksRealtimeReceived event,
    Emitter<CourierTasksState> emit,
  ) {
    if (event.tasks.isEmpty && state.tasks.isNotEmpty) return;

    final counts = _calculateCounts(event.tasks);
    emit(state.copyWith(
      status: CourierTasksStatus.success,
      tasks: event.tasks,
      counts: counts,
      lastUpdatedAt: DateTime.now(),
      errorMessage: null,
    ));
  }

  Map<CourierTaskGroup, int> _calculateCounts(List<CourierTask> tasks) {
    int pending = 0;
    int inProgress = 0;
    int completed = 0;

    for (final t in tasks) {
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

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }
}
