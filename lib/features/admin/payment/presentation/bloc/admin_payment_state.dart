import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_payment_detail.dart';
import '../../domain/entities/admin_payment_item.dart';

enum AdminPaymentStatus {
  initial,
  loading,
  loaded,
  unauthorized,
  error,
}

class AdminPaymentState extends Equatable {
  final AdminPaymentStatus status;
  final AdminPaymentsPaginatedResult paymentsResult;
  final AdminPaymentDetail? selectedDetail;
  final AdminPaymentPeriod selectedPeriod;

  final String activeTab;
  final String searchQuery;
  final String methodFilter;
  final String statusFilter;
  final String jenisBankFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final num? minAmount;
  final num? maxAmount;

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

  const AdminPaymentState({
    this.status = AdminPaymentStatus.initial,
    this.paymentsResult = AdminPaymentsPaginatedResult.empty,
    this.selectedDetail,
    this.selectedPeriod = AdminPaymentPeriod.daily,
    this.activeTab = AdminPaymentTab.all,
    this.searchQuery = '',
    this.methodFilter = 'ALL',
    this.statusFilter = 'ALL',
    this.jenisBankFilter = 'ALL',
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortColumn = 'created_at',
    this.sortAscending = false,
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

  AdminPaymentState copyWith({
    AdminPaymentStatus? status,
    AdminPaymentsPaginatedResult? paymentsResult,
    AdminPaymentDetail? selectedDetail,
    bool clearSelectedDetail = false,
    AdminPaymentPeriod? selectedPeriod,
    String? activeTab,
    String? searchQuery,
    String? methodFilter,
    String? statusFilter,
    String? jenisBankFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    num? minAmount,
    num? maxAmount,
    bool clearAmounts = false,
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
    return AdminPaymentState(
      status: status ?? this.status,
      paymentsResult: paymentsResult ?? this.paymentsResult,
      selectedDetail: clearSelectedDetail
          ? null
          : (selectedDetail ?? this.selectedDetail),
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      methodFilter: methodFilter ?? this.methodFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      jenisBankFilter: jenisBankFilter ?? this.jenisBankFilter,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
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
        paymentsResult,
        selectedDetail,
        selectedPeriod,
        activeTab,
        searchQuery,
        methodFilter,
        statusFilter,
        jenisBankFilter,
        startDate,
        endDate,
        minAmount,
        maxAmount,
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

