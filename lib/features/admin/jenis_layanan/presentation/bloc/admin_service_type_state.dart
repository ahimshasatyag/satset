import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_service_type_detail.dart';
import '../../domain/entities/admin_service_type_item.dart';

enum AdminServiceTypeStatus {
  initial,
  loading,
  loaded,
  unauthorized,
  error,
}

class AdminServiceTypeState extends Equatable {
  final AdminServiceTypeStatus status;
  final AdminServiceTypesPaginatedResult servicesResult;
  final AdminServiceTypeDetail? selectedDetail;

  final String searchQuery;
  final String statusFilter;
  final String sortColumn;
  final bool sortAscending;
  final int currentPage;
  final int pageSize;

  final bool isRefreshing;
  final bool isTableLoading;
  final bool isDetailLoading;
  final bool isActionInProgress;
  final String? errorMessage;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const AdminServiceTypeState({
    this.status = AdminServiceTypeStatus.initial,
    this.servicesResult = AdminServiceTypesPaginatedResult.empty,
    this.selectedDetail,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.sortColumn = 'id',
    this.sortAscending = true,
    this.currentPage = 1,
    this.pageSize = 10,
    this.isRefreshing = false,
    this.isTableLoading = false,
    this.isDetailLoading = false,
    this.isActionInProgress = false,
    this.errorMessage,
    this.actionSuccessMessage,
    this.actionErrorMessage,
  });

  AdminServiceTypeState copyWith({
    AdminServiceTypeStatus? status,
    AdminServiceTypesPaginatedResult? servicesResult,
    AdminServiceTypeDetail? selectedDetail,
    bool clearSelectedDetail = false,
    String? searchQuery,
    String? statusFilter,
    String? sortColumn,
    bool? sortAscending,
    int? currentPage,
    int? pageSize,
    bool? isRefreshing,
    bool? isTableLoading,
    bool? isDetailLoading,
    bool? isActionInProgress,
    String? errorMessage,
    String? actionSuccessMessage,
    String? actionErrorMessage,
    bool clearNotifications = false,
  }) {
    return AdminServiceTypeState(
      status: status ?? this.status,
      servicesResult: servicesResult ?? this.servicesResult,
      selectedDetail: clearSelectedDetail
          ? null
          : (selectedDetail ?? this.selectedDetail),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isTableLoading: isTableLoading ?? this.isTableLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      actionSuccessMessage: clearNotifications
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      actionErrorMessage: clearNotifications
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        servicesResult,
        selectedDetail,
        searchQuery,
        statusFilter,
        sortColumn,
        sortAscending,
        currentPage,
        pageSize,
        isRefreshing,
        isTableLoading,
        isDetailLoading,
        isActionInProgress,
        errorMessage,
        actionSuccessMessage,
        actionErrorMessage,
      ];
}

