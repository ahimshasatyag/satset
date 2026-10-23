import 'package:equatable/equatable.dart';
import '../../domain/entities/courier_task.dart';

enum CourierTasksStatus {
  initial,
  loading,
  success,
  failure,
  updating,
}

class CourierTasksState extends Equatable {
  final CourierTasksStatus status;
  final List<CourierTask> tasks;
  final CourierTaskGroup selectedGroup;
  final CourierTaskType? selectedType;
  final String searchQuery;
  final int page;
  final bool hasReachedMax;
  final Map<CourierTaskGroup, int> counts;
  final DateTime? lastUpdatedAt;
  final String? errorMessage;
  final String? successMessage;
  final bool isOffline;

  const CourierTasksState({
    this.status = CourierTasksStatus.initial,
    this.tasks = const [],
    this.selectedGroup = CourierTaskGroup.pending,
    this.selectedType,
    this.searchQuery = '',
    this.page = 1,
    this.hasReachedMax = false,
    this.counts = const {
      CourierTaskGroup.pending: 0,
      CourierTaskGroup.inProgress: 0,
      CourierTaskGroup.completed: 0,
    },
    this.lastUpdatedAt,
    this.errorMessage,
    this.successMessage,
    this.isOffline = false,
  });

  /// Daftar tugas terfilter berdasarkan tab kelompok, jenis tugas, dan pencarian teks
  List<CourierTask> get displayedTasks {
    var result = tasks.where((t) => t.taskGroup == selectedGroup).toList();

    if (selectedType != null) {
      result = result.where((t) => t.taskType == selectedType).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((t) {
        return t.trackingNumber.toLowerCase().contains(q) ||
            t.barcodeValue.toLowerCase().contains(q) ||
            t.receiverName.toLowerCase().contains(q) ||
            t.senderName.toLowerCase().contains(q) ||
            t.targetAddress.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  int get pendingCount => counts[CourierTaskGroup.pending] ?? 0;
  int get inProgressCount => counts[CourierTaskGroup.inProgress] ?? 0;
  int get completedCount => counts[CourierTaskGroup.completed] ?? 0;

  bool get isLoading => status == CourierTasksStatus.loading;
  bool get isUpdating => status == CourierTasksStatus.updating;

  CourierTasksState copyWith({
    CourierTasksStatus? status,
    List<CourierTask>? tasks,
    CourierTaskGroup? selectedGroup,
    CourierTaskType? selectedType,
    bool clearTypeFilter = false,
    String? searchQuery,
    int? page,
    bool? hasReachedMax,
    Map<CourierTaskGroup, int>? counts,
    DateTime? lastUpdatedAt,
    String? errorMessage,
    String? successMessage,
    bool? isOffline,
  }) {
    return CourierTasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      selectedType: clearTypeFilter ? null : (selectedType ?? this.selectedType),
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      counts: counts ?? this.counts,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        selectedGroup,
        selectedType,
        searchQuery,
        page,
        hasReachedMax,
        counts,
        lastUpdatedAt,
        errorMessage,
        successMessage,
        isOffline,
      ];
}
