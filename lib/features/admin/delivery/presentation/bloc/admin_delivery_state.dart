import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_assignable_courier.dart';
import '../../domain/entities/admin_delivery_detail.dart';
import '../../domain/entities/admin_delivery_item.dart';

enum AdminDeliveryStatus {
  initial,
  loading,
  loaded,
  unauthorized,
  error,
}

class AdminDeliveryState extends Equatable {
  final AdminDeliveryStatus status;
  final AdminDeliveriesPaginatedResult deliveriesResult;
  final List<AdminAssignableCourier> couriers;
  final List<Map<String, dynamic>> statusOptions;
  final List<Map<String, dynamic>> serviceOptions;

  // Filter & Pencarian Aktif
  final String activeTab;
  final String searchQuery;
  final String statusFilter;
  final String paymentMethodFilter;
  final String paymentStatusFilter;
  final String serviceFilter;
  final String courierFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortColumn;
  final bool sortAscending;
  final int currentPage;
  final int pageSize;

  // Detail & Tindakan
  final AdminDeliveryDetail? selectedDetail;
  final bool isTableLoading;
  final bool isRefreshing;
  final bool isDetailLoading;
  final bool isActionInProgress;
  final String? errorMessage;
  final String? actionSuccessMessage;
  final String? actionErrorMessage;

  const AdminDeliveryState({
    this.status = AdminDeliveryStatus.initial,
    this.deliveriesResult = AdminDeliveriesPaginatedResult.empty,
    this.couriers = const [],
    this.statusOptions = const [],
    this.serviceOptions = const [],
    this.activeTab = AdminDeliveryTab.all,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.paymentMethodFilter = 'ALL',
    this.paymentStatusFilter = 'ALL',
    this.serviceFilter = 'ALL',
    this.courierFilter = 'ALL',
    this.startDate,
    this.endDate,
    this.sortColumn = 'created_at',
    this.sortAscending = false,
    this.currentPage = 1,
    this.pageSize = 10,
    this.selectedDetail,
    this.isTableLoading = false,
    this.isRefreshing = false,
    this.isDetailLoading = false,
    this.isActionInProgress = false,
    this.errorMessage,
    this.actionSuccessMessage,
    this.actionErrorMessage,
  });

  AdminDeliveryState copyWith({
    AdminDeliveryStatus? status,
    AdminDeliveriesPaginatedResult? deliveriesResult,
    List<AdminAssignableCourier>? couriers,
    List<Map<String, dynamic>>? statusOptions,
    List<Map<String, dynamic>>? serviceOptions,
    String? activeTab,
    String? searchQuery,
    String? statusFilter,
    String? paymentMethodFilter,
    String? paymentStatusFilter,
    String? serviceFilter,
    String? courierFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    String? sortColumn,
    bool? sortAscending,
    int? currentPage,
    int? pageSize,
    AdminDeliveryDetail? selectedDetail,
    bool clearSelectedDetail = false,
    bool? isTableLoading,
    bool? isRefreshing,
    bool? isDetailLoading,
    bool? isActionInProgress,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionSuccessMessage,
    bool clearActionSuccessMessage = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
  }) {
    return AdminDeliveryState(
      status: status ?? this.status,
      deliveriesResult: deliveriesResult ?? this.deliveriesResult,
      couriers: couriers ?? this.couriers,
      statusOptions: statusOptions ?? this.statusOptions,
      serviceOptions: serviceOptions ?? this.serviceOptions,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      paymentMethodFilter: paymentMethodFilter ?? this.paymentMethodFilter,
      paymentStatusFilter: paymentStatusFilter ?? this.paymentStatusFilter,
      serviceFilter: serviceFilter ?? this.serviceFilter,
      courierFilter: courierFilter ?? this.courierFilter,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      selectedDetail:
          clearSelectedDetail ? null : (selectedDetail ?? this.selectedDetail),
      isTableLoading: isTableLoading ?? this.isTableLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionSuccessMessage: clearActionSuccessMessage
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      actionErrorMessage: clearActionErrorMessage
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        deliveriesResult,
        couriers,
        statusOptions,
        serviceOptions,
        activeTab,
        searchQuery,
        statusFilter,
        paymentMethodFilter,
        paymentStatusFilter,
        serviceFilter,
        courierFilter,
        startDate,
        endDate,
        sortColumn,
        sortAscending,
        currentPage,
        pageSize,
        selectedDetail,
        isTableLoading,
        isRefreshing,
        isDetailLoading,
        isActionInProgress,
        errorMessage,
        actionSuccessMessage,
        actionErrorMessage,
      ];
}

