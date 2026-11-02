import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_courier_summary.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_shipment_detail.dart';
import '../../domain/entities/admin_shipment_table_item.dart';

enum AdminDashboardStatus {
  initial,
  loading,
  success,
  unauthorized,
  error,
}

class AdminDashboardState extends Equatable {
  final AdminDashboardStatus status;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isTableLoading;
  final bool isDetailLoading;

  // Data Statistik & Ringkasan
  final AdminDashboardStats stats;
  final List<AdminCourierSummary> couriers;
  final List<AdminActivity> activities;

  // Filter & Pagination Tabel
  final AdminShipmentsPaginatedResult shipmentsResult;
  final String searchQuery;
  final String statusFilter;
  final String serviceFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final int currentPage;

  // Referensi Pilihan Filter
  final List<Map<String, dynamic>> statusOptions;
  final List<Map<String, dynamic>> serviceOptions;
  final List<Map<String, dynamic>> courierOptions;

  // Tampilan Grafik Tren Aktif: 'DAILY', 'WEEKLY', 'MONTHLY'
  final String activeTrendPeriod;

  // Modal Detail Pengiriman
  final AdminShipmentDetail? selectedShipmentDetail;
  final String? detailErrorMessage;

  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.errorMessage,
    this.isRefreshing = false,
    this.isTableLoading = false,
    this.isDetailLoading = false,
    this.stats = AdminDashboardStats.empty,
    this.couriers = const [],
    this.activities = const [],
    this.shipmentsResult = AdminShipmentsPaginatedResult.empty,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.serviceFilter = 'ALL',
    this.startDate,
    this.endDate,
    this.currentPage = 1,
    this.statusOptions = const [],
    this.serviceOptions = const [],
    this.courierOptions = const [],
    this.activeTrendPeriod = 'DAILY',
    this.selectedShipmentDetail,
    this.detailErrorMessage,
  });

  AdminDashboardState copyWith({
    AdminDashboardStatus? status,
    String? errorMessage,
    bool? isRefreshing,
    bool? isTableLoading,
    bool? isDetailLoading,
    AdminDashboardStats? stats,
    List<AdminCourierSummary>? couriers,
    List<AdminActivity>? activities,
    AdminShipmentsPaginatedResult? shipmentsResult,
    String? searchQuery,
    String? statusFilter,
    String? serviceFilter,
    DateTime? startDate,
    DateTime? endDate,
    int? currentPage,
    List<Map<String, dynamic>>? statusOptions,
    List<Map<String, dynamic>>? serviceOptions,
    List<Map<String, dynamic>>? courierOptions,
    String? activeTrendPeriod,
    AdminShipmentDetail? selectedShipmentDetail,
    bool clearSelectedDetail = false,
    String? detailErrorMessage,
  }) {
    return AdminDashboardState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isTableLoading: isTableLoading ?? this.isTableLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      stats: stats ?? this.stats,
      couriers: couriers ?? this.couriers,
      activities: activities ?? this.activities,
      shipmentsResult: shipmentsResult ?? this.shipmentsResult,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      serviceFilter: serviceFilter ?? this.serviceFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentPage: currentPage ?? this.currentPage,
      statusOptions: statusOptions ?? this.statusOptions,
      serviceOptions: serviceOptions ?? this.serviceOptions,
      courierOptions: courierOptions ?? this.courierOptions,
      activeTrendPeriod: activeTrendPeriod ?? this.activeTrendPeriod,
      selectedShipmentDetail: clearSelectedDetail
          ? null
          : (selectedShipmentDetail ?? this.selectedShipmentDetail),
      detailErrorMessage: detailErrorMessage ?? this.detailErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        isRefreshing,
        isTableLoading,
        isDetailLoading,
        stats,
        couriers,
        activities,
        shipmentsResult,
        searchQuery,
        statusFilter,
        serviceFilter,
        startDate,
        endDate,
        currentPage,
        statusOptions,
        serviceOptions,
        courierOptions,
        activeTrendPeriod,
        selectedShipmentDetail,
        detailErrorMessage,
      ];
}

