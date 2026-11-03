import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_customer_detail.dart';
import '../../domain/entities/admin_customer_item.dart';

enum AdminCustomerStatus {
  initial,
  loading,
  loaded,
  unauthorized,
  error,
}

class AdminCustomerState extends Equatable {
  final AdminCustomerStatus status;
  final AdminCustomersPaginatedResult customersResult;
  final String searchQuery;
  final String verificationFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortColumn;
  final bool sortAscending;
  final int currentPage;
  final bool isTableLoading;
  final bool isRefreshing;
  final bool isActionInProgress;
  final bool isDetailLoading;
  final AdminCustomerDetail? selectedDetail;
  final String? errorMessage;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const AdminCustomerState({
    this.status = AdminCustomerStatus.initial,
    this.customersResult = AdminCustomersPaginatedResult.empty,
    this.searchQuery = '',
    this.verificationFilter = 'ALL',
    this.startDate,
    this.endDate,
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

  AdminCustomerState copyWith({
    AdminCustomerStatus? status,
    AdminCustomersPaginatedResult? customersResult,
    String? searchQuery,
    String? verificationFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    String? sortColumn,
    bool? sortAscending,
    int? currentPage,
    bool? isTableLoading,
    bool? isRefreshing,
    bool? isActionInProgress,
    bool? isDetailLoading,
    AdminCustomerDetail? selectedDetail,
    bool clearSelectedDetail = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionSuccessMessage,
    String? actionErrorMessage,
    bool clearActionMessages = false,
  }) {
    return AdminCustomerState(
      status: status ?? this.status,
      customersResult: customersResult ?? this.customersResult,
      searchQuery: searchQuery ?? this.searchQuery,
      verificationFilter: verificationFilter ?? this.verificationFilter,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
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
        customersResult,
        searchQuery,
        verificationFilter,
        startDate,
        endDate,
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

