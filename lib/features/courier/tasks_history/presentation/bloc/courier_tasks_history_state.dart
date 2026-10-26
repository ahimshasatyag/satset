import 'package:equatable/equatable.dart';
import '../../domain/entities/courier_task_history_detail.dart';
import '../../domain/entities/courier_task_history_item.dart';
import '../../domain/entities/courier_task_history_stats.dart';

enum CourierTaskHistoryStatus {
  initial,
  loading,
  success,
  failure,
  loadingMore,
}

class CourierTasksHistoryState extends Equatable {
  final CourierTaskHistoryStatus status;
  final List<CourierTaskHistoryItem> tasks;
  final CourierTaskHistoryStats stats;

  /// Parameter Filter
  final String searchQuery;
  final CourierHistoryTaskType selectedTaskType;
  final String selectedStatusCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? datePresetLabel;

  /// Pagination
  final int page;
  final bool hasReachedMax;

  /// Error state
  final String? errorMessage;

  /// Detail state untuk bottom sheet riwayat
  final CourierTaskHistoryDetail? detail;
  final bool isDetailLoading;
  final String? detailError;

  const CourierTasksHistoryState({
    this.status = CourierTaskHistoryStatus.initial,
    this.tasks = const [],
    this.stats = const CourierTaskHistoryStats(),
    this.searchQuery = '',
    this.selectedTaskType = CourierHistoryTaskType.all,
    this.selectedStatusCode = 'ALL',
    this.startDate,
    this.endDate,
    this.datePresetLabel,
    this.page = 1,
    this.hasReachedMax = false,
    this.errorMessage,
    this.detail,
    this.isDetailLoading = false,
    this.detailError,
  });

  /// True jika ada filter non-default yang sedang aktif
  bool get hasActiveFilters {
    return searchQuery.trim().isNotEmpty ||
        selectedTaskType != CourierHistoryTaskType.all ||
        (selectedStatusCode.toUpperCase() != 'ALL' &&
            selectedStatusCode.trim().isNotEmpty) ||
        startDate != null ||
        endDate != null;
  }

  /// Jumlah filter aktif
  int get activeFilterCount {
    int count = 0;
    if (selectedTaskType != CourierHistoryTaskType.all) {
      count++;
    }
    if (selectedStatusCode.toUpperCase() != 'ALL' &&
        selectedStatusCode.trim().isNotEmpty) {
      count++;
    }
    if (startDate != null || endDate != null) {
      count++;
    }
    return count;
  }

  CourierTasksHistoryState copyWith({
    CourierTaskHistoryStatus? status,
    List<CourierTaskHistoryItem>? tasks,
    CourierTaskHistoryStats? stats,
    String? searchQuery,
    CourierHistoryTaskType? selectedTaskType,
    String? selectedStatusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? datePresetLabel,
    int? page,
    bool? hasReachedMax,
    String? errorMessage,
    CourierTaskHistoryDetail? detail,
    bool? isDetailLoading,
    String? detailError,
    bool clearDetail = false,
    bool clearDates = false,
  }) {
    return CourierTasksHistoryState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      stats: stats ?? this.stats,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTaskType: selectedTaskType ?? this.selectedTaskType,
      selectedStatusCode: selectedStatusCode ?? this.selectedStatusCode,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      datePresetLabel: clearDates ? null : (datePresetLabel ?? this.datePresetLabel),
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage,
      detail: clearDetail ? null : (detail ?? this.detail),
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      detailError: detailError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        stats,
        searchQuery,
        selectedTaskType,
        selectedStatusCode,
        startDate,
        endDate,
        datePresetLabel,
        page,
        hasReachedMax,
        errorMessage,
        detail,
        isDetailLoading,
        detailError,
      ];
}
