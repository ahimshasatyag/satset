import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/admin_dashboard_remote_datasource.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../../domain/usecases/get_admin_dashboard_stats_usecase.dart';
import '../../domain/usecases/get_admin_shipment_detail_usecase.dart';
import '../../domain/usecases/get_admin_shipments_table_usecase.dart';
import 'admin_dashboard_event.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminDashboardRepository repository;
  final AdminDashboardRemoteDataSource remoteDataSource;
  final GetAdminDashboardStatsUseCase getStatsUseCase;
  final GetAdminShipmentsTableUseCase getShipmentsTableUseCase;
  final GetAdminShipmentDetailUseCase getShipmentDetailUseCase;

  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;

  AdminDashboardBloc({
    required this.repository,
    required this.remoteDataSource,
  })  : getStatsUseCase = GetAdminDashboardStatsUseCase(repository),
        getShipmentsTableUseCase = GetAdminShipmentsTableUseCase(repository),
        getShipmentDetailUseCase = GetAdminShipmentDetailUseCase(repository),
        super(const AdminDashboardState()) {
    on<AdminDashboardStarted>(_onStarted);
    on<AdminDashboardRefreshed>(_onRefreshed);
    on<AdminDashboardTrendPeriodChanged>(_onTrendPeriodChanged);
    on<AdminDashboardSearchQueryChanged>(_onSearchQueryChanged);
    on<AdminDashboardStatusFilterChanged>(_onStatusFilterChanged);
    on<AdminDashboardServiceFilterChanged>(_onServiceFilterChanged);
    on<AdminDashboardDateRangeFilterChanged>(_onDateRangeFilterChanged);
    on<AdminDashboardPageChanged>(_onPageChanged);
    on<AdminDashboardShipmentDetailRequested>(_onShipmentDetailRequested);
    on<AdminDashboardShipmentDetailDismissed>(_onShipmentDetailDismissed);
    on<AdminDashboardRealtimeTriggered>(_onRealtimeTriggered);
  }

  Future<void> _onStarted(
    AdminDashboardStarted event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(status: AdminDashboardStatus.loading));

    try {
      // 1. Verifikasi hak akses admin (id_users_role = 1 / employee_type = 'ADMIN')
      final isAuthorized = await repository.verifyAdminAccess();
      if (!isAuthorized) {
        emit(state.copyWith(
          status: AdminDashboardStatus.unauthorized,
          errorMessage: 'Akses Ditolak: Halaman ini hanya dapat diakses oleh akun Administrator SatSet Delivery.',
        ));
        return;
      }

      // 2. Ambil data agregat dashboard & tabel
      final initialData = await getStatsUseCase.execute();
      final tableResult = await getShipmentsTableUseCase.execute(
        page: 1,
        pageSize: 10,
      );

      // 3. Daftarkan langganan Supabase Realtime
      _setupRealtimeSubscription();

      emit(state.copyWith(
        status: AdminDashboardStatus.success,
        stats: initialData.stats,
        couriers: initialData.couriers,
        activities: initialData.activities,
        statusOptions: initialData.statusOptions,
        serviceOptions: initialData.serviceOptions,
        courierOptions: initialData.courierOptions,
        shipmentsResult: tableResult,
        currentPage: 1,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AdminDashboardStatus.error,
        errorMessage: 'Gagal memuat data Dashboard Admin: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshed(
    AdminDashboardRefreshed event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      final initialData = await getStatsUseCase.execute();
      final tableResult = await getShipmentsTableUseCase.execute(
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        serviceFilter: state.serviceFilter,
        startDate: state.startDate,
        endDate: state.endDate,
        page: state.currentPage,
        pageSize: 10,
      );

      emit(state.copyWith(
        isRefreshing: false,
        stats: initialData.stats,
        couriers: initialData.couriers,
        activities: initialData.activities,
        statusOptions: initialData.statusOptions,
        serviceOptions: initialData.serviceOptions,
        courierOptions: initialData.courierOptions,
        shipmentsResult: tableResult,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: 'Gagal menyegarkan data: ${e.toString()}',
      ));
    }
  }

  void _onTrendPeriodChanged(
    AdminDashboardTrendPeriodChanged event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(activeTrendPeriod: event.period));
  }

  Future<void> _onSearchQueryChanged(
    AdminDashboardSearchQueryChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: event.query,
      currentPage: 1,
      isTableLoading: true,
    ));

    try {
      final tableResult = await getShipmentsTableUseCase.execute(
        searchQuery: event.query,
        statusFilter: state.statusFilter,
        serviceFilter: state.serviceFilter,
        startDate: state.startDate,
        endDate: state.endDate,
        page: 1,
        pageSize: 10,
      );

      emit(state.copyWith(
        shipmentsResult: tableResult,
        isTableLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTableLoading: false,
        errorMessage: 'Gagal memfilter pengiriman: $e',
      ));
    }
  }

  Future<void> _onStatusFilterChanged(
    AdminDashboardStatusFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(
      statusFilter: event.status,
      currentPage: 1,
      isTableLoading: true,
    ));

    try {
      final tableResult = await getShipmentsTableUseCase.execute(
        searchQuery: state.searchQuery,
        statusFilter: event.status,
        serviceFilter: state.serviceFilter,
        startDate: state.startDate,
        endDate: state.endDate,
        page: 1,
        pageSize: 10,
      );

      emit(state.copyWith(
        shipmentsResult: tableResult,
        isTableLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTableLoading: false,
        errorMessage: 'Gagal memfilter status: $e',
      ));
    }
  }

  Future<void> _onServiceFilterChanged(
    AdminDashboardServiceFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(
      serviceFilter: event.service,
      currentPage: 1,
      isTableLoading: true,
    ));

    try {
      final tableResult = await getShipmentsTableUseCase.execute(
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        serviceFilter: event.service,
        startDate: state.startDate,
        endDate: state.endDate,
        page: 1,
        pageSize: 10,
      );

      emit(state.copyWith(
        shipmentsResult: tableResult,
        isTableLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTableLoading: false,
        errorMessage: 'Gagal memfilter layanan: $e',
      ));
    }
  }

  Future<void> _onDateRangeFilterChanged(
    AdminDashboardDateRangeFilterChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
      currentPage: 1,
      isTableLoading: true,
    ));

    try {
      final tableResult = await getShipmentsTableUseCase.execute(
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        serviceFilter: state.serviceFilter,
        startDate: event.startDate,
        endDate: event.endDate,
        page: 1,
        pageSize: 10,
      );

      emit(state.copyWith(
        shipmentsResult: tableResult,
        isTableLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTableLoading: false,
        errorMessage: 'Gagal memfilter tanggal: $e',
      ));
    }
  }

  Future<void> _onPageChanged(
    AdminDashboardPageChanged event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(
      currentPage: event.page,
      isTableLoading: true,
    ));

    try {
      final tableResult = await getShipmentsTableUseCase.execute(
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        serviceFilter: state.serviceFilter,
        startDate: state.startDate,
        endDate: state.endDate,
        page: event.page,
        pageSize: 10,
      );

      emit(state.copyWith(
        shipmentsResult: tableResult,
        isTableLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isTableLoading: false,
        errorMessage: 'Gagal memuat halaman: $e',
      ));
    }
  }

  Future<void> _onShipmentDetailRequested(
    AdminDashboardShipmentDetailRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(
      isDetailLoading: true,
      clearSelectedDetail: true,
      detailErrorMessage: null,
    ));

    try {
      final detail = await getShipmentDetailUseCase.execute(event.shipmentId);
      emit(state.copyWith(
        isDetailLoading: false,
        selectedShipmentDetail: detail,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDetailLoading: false,
        detailErrorMessage: 'Gagal memuat kronologi: $e',
      ));
    }
  }

  void _onShipmentDetailDismissed(
    AdminDashboardShipmentDetailDismissed event,
    Emitter<AdminDashboardState> emit,
  ) {
    emit(state.copyWith(clearSelectedDetail: true, detailErrorMessage: null));
  }

  void _onRealtimeTriggered(
    AdminDashboardRealtimeTriggered event,
    Emitter<AdminDashboardState> emit,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      add(const AdminDashboardRefreshed());
    });
  }

  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = remoteDataSource.subscribeToRealtimeUpdates(
        onDataChanged: () {
          add(const AdminDashboardRealtimeTriggered());
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    try {
      _realtimeChannel?.unsubscribe();
    } catch (_) {}
    return super.close();
  }
}

