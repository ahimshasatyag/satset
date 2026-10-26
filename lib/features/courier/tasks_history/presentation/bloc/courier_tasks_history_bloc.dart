import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/courier_task_history_item.dart';
import '../../domain/usecases/get_courier_task_history_detail_usecase.dart';
import '../../domain/usecases/get_courier_task_history_stats_usecase.dart';
import '../../domain/usecases/get_courier_tasks_history_usecase.dart';
import 'courier_tasks_history_event.dart';
import 'courier_tasks_history_state.dart';

class CourierTasksHistoryBloc
    extends Bloc<CourierTasksHistoryEvent, CourierTasksHistoryState> {
  final GetCourierTasksHistoryUseCase getCourierTasksHistoryUseCase;
  final GetCourierTaskHistoryDetailUseCase getCourierTaskHistoryDetailUseCase;
  final GetCourierTaskHistoryStatsUseCase getCourierTaskHistoryStatsUseCase;
  final String? courierId;

  static const int _pageSize = 20;

  CourierTasksHistoryBloc({
    required this.getCourierTasksHistoryUseCase,
    required this.getCourierTaskHistoryDetailUseCase,
    required this.getCourierTaskHistoryStatsUseCase,
    this.courierId,
  }) : super(const CourierTasksHistoryState()) {
    on<CourierTaskHistoryFetched>(_onFetched);
    on<CourierTaskHistoryLoadMore>(_onLoadMore);
    on<CourierTaskHistorySearchChanged>(_onSearchChanged);
    on<CourierTaskHistoryDateRangeChanged>(_onDateRangeChanged);
    on<CourierTaskHistoryTaskTypeChanged>(_onTaskTypeChanged);
    on<CourierTaskHistoryStatusFilterChanged>(_onStatusFilterChanged);
    on<CourierTaskHistoryFiltersReset>(_onFiltersReset);
    on<CourierTaskHistoryDetailRequested>(_onDetailRequested);
    on<CourierTaskHistoryDetailDismissed>(_onDetailDismissed);
  }

  Future<void> _onFetched(
    CourierTaskHistoryFetched event,
    Emitter<CourierTasksHistoryState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: CourierTaskHistoryStatus.loading));
    }

    try {
      // 1. Ambil data statistik riwayat secara paralel
      final statsFuture =
          getCourierTaskHistoryStatsUseCase(courierId: courierId);

      // 2. Ambil halaman pertama riwayat sesuai filter aktif
      final tasksFuture = getCourierTasksHistoryUseCase(
        GetCourierTasksHistoryParams(
          courierId: courierId,
          taskType: state.selectedTaskType,
          statusCode: state.selectedStatusCode == 'ALL'
              ? null
              : state.selectedStatusCode,
          startDate: state.startDate,
          endDate: state.endDate,
          searchQuery: state.searchQuery,
          page: 1,
          limit: _pageSize,
        ),
      );

      final results = await Future.wait([statsFuture, tasksFuture]);
      final stats = results[0] as dynamic;
      final tasks = results[1] as List<CourierTaskHistoryItem>;

      emit(state.copyWith(
        status: CourierTaskHistoryStatus.success,
        tasks: tasks,
        stats: stats,
        page: 1,
        hasReachedMax: tasks.length < _pageSize,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CourierTaskHistoryStatus.failure,
        errorMessage: 'Gagal memuat riwayat tugas kurir: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadMore(
    CourierTaskHistoryLoadMore event,
    Emitter<CourierTasksHistoryState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.status == CourierTaskHistoryStatus.loadingMore ||
        state.status == CourierTaskHistoryStatus.loading) {
      return;
    }

    emit(state.copyWith(status: CourierTaskHistoryStatus.loadingMore));

    final nextPage = state.page + 1;

    try {
      final moreTasks = await getCourierTasksHistoryUseCase(
        GetCourierTasksHistoryParams(
          courierId: courierId,
          taskType: state.selectedTaskType,
          statusCode: state.selectedStatusCode == 'ALL'
              ? null
              : state.selectedStatusCode,
          startDate: state.startDate,
          endDate: state.endDate,
          searchQuery: state.searchQuery,
          page: nextPage,
          limit: _pageSize,
        ),
      );

      final updatedTasks = List<CourierTaskHistoryItem>.from(state.tasks)
        ..addAll(moreTasks);

      emit(state.copyWith(
        status: CourierTaskHistoryStatus.success,
        tasks: updatedTasks,
        page: nextPage,
        hasReachedMax: moreTasks.length < _pageSize,
      ));
    } catch (_) {
      // Pertahankan data saat ini jika pemuatan berikutnya bermasalah
      emit(state.copyWith(status: CourierTaskHistoryStatus.success));
    }
  }

  void _onSearchChanged(
    CourierTaskHistorySearchChanged event,
    Emitter<CourierTasksHistoryState> emit,
  ) {
    if (state.searchQuery == event.query) return;
    emit(state.copyWith(searchQuery: event.query));
    add(const CourierTaskHistoryFetched());
  }

  void _onDateRangeChanged(
    CourierTaskHistoryDateRangeChanged event,
    Emitter<CourierTasksHistoryState> emit,
  ) {
    emit(state.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
      datePresetLabel: event.presetLabel,
      clearDates: event.startDate == null && event.endDate == null,
    ));
    add(const CourierTaskHistoryFetched());
  }

  void _onTaskTypeChanged(
    CourierTaskHistoryTaskTypeChanged event,
    Emitter<CourierTasksHistoryState> emit,
  ) {
    if (state.selectedTaskType == event.taskType) return;
    emit(state.copyWith(selectedTaskType: event.taskType));
    add(const CourierTaskHistoryFetched());
  }

  void _onStatusFilterChanged(
    CourierTaskHistoryStatusFilterChanged event,
    Emitter<CourierTasksHistoryState> emit,
  ) {
    if (state.selectedStatusCode == event.statusCode) return;
    emit(state.copyWith(selectedStatusCode: event.statusCode));
    add(const CourierTaskHistoryFetched());
  }

  void _onFiltersReset(
    CourierTaskHistoryFiltersReset event,
    Emitter<CourierTasksHistoryState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: '',
      selectedTaskType: CourierHistoryTaskType.all,
      selectedStatusCode: 'ALL',
      clearDates: true,
    ));
    add(const CourierTaskHistoryFetched());
  }

  Future<void> _onDetailRequested(
    CourierTaskHistoryDetailRequested event,
    Emitter<CourierTasksHistoryState> emit,
  ) async {
    emit(state.copyWith(
      isDetailLoading: true,
      detailError: null,
      clearDetail: true,
    ));

    try {
      final detail = await getCourierTaskHistoryDetailUseCase(
        shipmentId: event.shipmentId,
        taskId: event.taskId,
        courierId: courierId,
      );

      emit(state.copyWith(
        isDetailLoading: false,
        detail: detail,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDetailLoading: false,
        detailError: 'Gagal memuat detail riwayat: ${e.toString()}',
      ));
    }
  }

  void _onDetailDismissed(
    CourierTaskHistoryDetailDismissed event,
    Emitter<CourierTasksHistoryState> emit,
  ) {
    emit(state.copyWith(clearDetail: true));
  }
}
