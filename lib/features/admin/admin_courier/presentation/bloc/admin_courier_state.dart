import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_courier_detail.dart';
import '../../domain/entities/admin_courier_item.dart';

enum AdminCourierStatus {
  initial,
  loading,
  loaded,
  unauthorized,
  error,
}

class AdminCourierState extends Equatable {
  final AdminCourierStatus status;
  final AdminCouriersPaginatedResult couriersResult;
  final String searchQuery;
  final String accountStatusFilter;
  final String activityStatusFilter;
  final String sortColumn;
  final bool sortAscending;
  final int currentPage;
  final bool isTableLoading;
  final bool isRefreshing;
  final bool isActionInProgress;
  final bool isDetailLoading;
  final AdminCourierDetail? selectedDetail;
  final String? errorMessage;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const AdminCourierState({
    this.status = AdminCourierStatus.initial,
    this.couriersResult = AdminCouriersPaginatedResult.empty,
    this.searchQuery = '',
    this.accountStatusFilter = 'ALL',
    this.activityStatusFilter = 'ALL',
    this.sortColumn = 'created_at',
    this.sortAscending = false,
    this.currentPage = 1,
    this.isTableLoading = false,
    this.isRefreshing = false,
    this.isActionInProgress = false,
    this.isDetailLoading = false,
    this.selectedDetail,
    this.errorMessage,
    this.actionSuccessMessage,
    this.actionErrorMessage,
  });

  AdminCourierState copyWith({
    AdminCourierStatus? status,
    AdminCouriersPaginatedResult? couriersResult,
    String? searchQuery,
    String? accountStatusFilter,
    String? activityStatusFilter,
    String? sortColumn,
    bool? sortAscending,
    int? currentPage,
    bool? isTableLoading,
    bool? isRefreshing,
    bool? isActionInProgress,
    bool? isDetailLoading,
    AdminCourierDetail? selectedDetail,
    bool clearSelectedDetail = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionSuccessMessage,
    String? actionErrorMessage,
    bool clearActionMessages = false,
  }) {
    return AdminCourierState(
      status: status ?? this.status,
      couriersResult: couriersResult ?? this.couriersResult,
      searchQuery: searchQuery ?? this.searchQuery,
      accountStatusFilter: accountStatusFilter ?? this.accountStatusFilter,
      activityStatusFilter: activityStatusFilter ?? this.activityStatusFilter,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
      currentPage: currentPage ?? this.currentPage,
      isTableLoading: isTableLoading ?? this.isTableLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      selectedDetail:
          clearSelectedDetail ? null : (selectedDetail ?? this.selectedDetail),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionSuccessMessage: clearActionMessages
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      actionErrorMessage: clearActionMessages
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        couriersResult,
        searchQuery,
        accountStatusFilter,
        activityStatusFilter,
        sortColumn,
        sortAscending,
        currentPage,
        isTableLoading,
        isRefreshing,
        isActionInProgress,
        isDetailLoading,
        selectedDetail,
        errorMessage,
        actionSuccessMessage,
        actionErrorMessage,
      ];
}

