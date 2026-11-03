import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/admin_delivery_remote_datasource.dart';
import '../../domain/entities/admin_assignable_courier.dart';
import '../../domain/entities/admin_delivery_item.dart';
import '../../domain/repositories/admin_delivery_repository.dart';
import 'admin_delivery_event.dart';
import 'admin_delivery_state.dart';

class AdminDeliveryBloc extends Bloc<AdminDeliveryEvent, AdminDeliveryState> {
  final AdminDeliveryRepository repository;
  final AdminDeliveryRemoteDataSource remoteDataSource;
  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;

  AdminDeliveryBloc({required this.repository, required this.remoteDataSource})
    : super(const AdminDeliveryState()) {
    on<AdminDeliveryStarted>(_onStarted);
    on<AdminDeliveryRefreshed>(_onRefreshed);
    on<AdminDeliveryRealtimeUpdated>(_onRealtimeUpdated);
    on<AdminDeliveryTabChanged>(_onTabChanged);
    on<AdminDeliverySearchChanged>(_onSearchChanged);
    on<AdminDeliveryFiltersUpdated>(_onFiltersUpdated);
    on<AdminDeliveryFiltersReset>(_onFiltersReset);
    on<AdminDeliverySortChanged>(_onSortChanged);
    on<AdminDeliveryPageChanged>(_onPageChanged);
    on<AdminDeliveryDetailRequested>(_onDetailRequested);
    on<AdminDeliveryDetailDismissed>(_onDetailDismissed);
    on<AdminDeliveryConfirmOrderRequested>(_onConfirmOrderRequested);
    on<AdminDeliveryAssignCourierRequested>(_onAssignCourierRequested);
    on<AdminDeliveryUpdateStatusRequested>(_onUpdateStatusRequested);
    on<AdminDeliveryHandleFailedRequested>(_onHandleFailedRequested);
    on<AdminDeliveryClearNotification>(_onClearNotification);
  }

  Future<void> _onStarted(
    AdminDeliveryStarted event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminDeliveryStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final isAdmin = await repository.verifyAdminAccess();
      if (!isAdmin) {
        emit(
          state.copyWith(
            status: AdminDeliveryStatus.unauthorized,
            errorMessage: 'Akses Ditolak: Hanya Administrator resmi (id_users_role = 1) yang memiliki izin mengakses Manajemen Pengiriman.',
          ),
        );
        return;
      }

      final results = await Future.wait([
        _fetchCurrentDeliveries(state),
        repository.getAssignableCouriers(),
        repository.getStatusReferences(),
        repository.getServiceTypeReferences(),
      ]);

      emit(
        state.copyWith(
          status: AdminDeliveryStatus.loaded,
          deliveriesResult: results[0] as AdminDeliveriesPaginatedResult,
          couriers: List<AdminAssignableCourier>.from(results[1] as List),
          statusOptions: results[2] as List<Map<String, dynamic>>,
          serviceOptions: results[3] as List<Map<String, dynamic>>,
        ),
      );

      _setupRealtimeSubscription();
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminDeliveryStatus.error,
          errorMessage:
              'Gagal memuat data manajemen pengiriman: ${e.toString()}',
        ),
      );
    }
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    try {
      _realtimeChannel = remoteDataSource.subscribeToRealtimeUpdates(
        onDataChanged: () {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 500), () {
            if (!isClosed) {
              add(const AdminDeliveryRealtimeUpdated());
            }
          });
        },
      );
    } catch (_) {}
  }

  Future<AdminDeliveriesPaginatedResult> _fetchCurrentDeliveries(
    AdminDeliveryState currentState,
  ) {
    return repository.getPaginatedDeliveries(
      tabCategory: currentState.activeTab,
      searchQuery: currentState.searchQuery,
      statusFilter: currentState.statusFilter,
      paymentMethodFilter: currentState.paymentMethodFilter,
      paymentStatusFilter: currentState.paymentStatusFilter,
      serviceFilter: currentState.serviceFilter,
      courierFilter: currentState.courierFilter,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
      sortColumn: currentState.sortColumn,
      sortAscending: currentState.sortAscending,
      page: currentState.currentPage,
      pageSize: currentState.pageSize,
    );
  }

  Future<void> _onRefreshed(
    AdminDeliveryRefreshed event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    emit(
      state.copyWith(
        isRefreshing: true,
        clearActionErrorMessage: true,
        clearActionSuccessMessage: true,
      ),
    );

    try {
      final deliveries = await _fetchCurrentDeliveries(state);
      final couriers = await repository.getAssignableCouriers();

      var updatedDetail = state.selectedDetail;
      if (updatedDetail != null) {
        try {
          updatedDetail = await repository.getDeliveryDetail(updatedDetail.id);
        } catch (_) {}
      }

      emit(
        state.copyWith(
          status: AdminDeliveryStatus.loaded,
          deliveriesResult: deliveries,
          couriers: couriers,
          selectedDetail: updatedDetail,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          actionErrorMessage: 'Gagal menyegarkan data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRealtimeUpdated(
    AdminDeliveryRealtimeUpdated event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    if (state.status != AdminDeliveryStatus.loaded) return;
    try {
      final deliveries = await _fetchCurrentDeliveries(state);
      final couriers = await repository.getAssignableCouriers();

      var updatedDetail = state.selectedDetail;
      if (updatedDetail != null) {
        try {
          updatedDetail = await repository.getDeliveryDetail(updatedDetail.id);
        } catch (_) {}
      }

      emit(
        state.copyWith(
          deliveriesResult: deliveries,
          couriers: couriers,
          selectedDetail: updatedDetail,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onTabChanged(
    AdminDeliveryTabChanged event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    final nextState = state.copyWith(
      activeTab: event.tabCategory,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);

    try {
      final deliveries = await _fetchCurrentDeliveries(nextState);
      emit(state.copyWith(deliveriesResult: deliveries, isTableLoading: false));
    } catch (_) {
      emit(state.copyWith(isTableLoading: false));
    }
  }

  Future<void> _onSearchChanged(
    AdminDeliverySearchChanged event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    final nextState = state.copyWith(
      searchQuery: event.query,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);

    try {
      final deliveries = await _fetchCurrentDeliveries(nextState);
      emit(state.copyWith(deliveriesResult: deliveries, isTableLoading: false));
    } catch (_) {
      emit(state.copyWith(isTableLoading: false));
    }
  }

  Future<void> _onFiltersUpdated(
    AdminDeliveryFiltersUpdated event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    final nextState = state.copyWith(
      statusFilter: event.statusFilter,
      paymentMethodFilter: event.paymentMethodFilter,
      paymentStatusFilter: event.paymentStatusFilter,
      serviceFilter: event.serviceFilter,
      courierFilter: event.courierFilter,
      startDate: event.startDate,
      endDate: event.endDate,
      clearDates: event.clearDates,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);

    try {
      final deliveries = await _fetchCurrentDeliveries(nextState);
      emit(state.copyWith(deliveriesResult: deliveries, isTableLoading: false));
    } catch (_) {
      emit(state.copyWith(isTableLoading: false));
    }
  }

  Future<void> _onFiltersReset(
    AdminDeliveryFiltersReset event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    final nextState = state.copyWith(
      activeTab: AdminDeliveryTab.all,
      searchQuery: '',
      statusFilter: 'ALL',
      paymentMethodFilter: 'ALL',
      paymentStatusFilter: 'ALL',
      serviceFilter: 'ALL',
      courierFilter: 'ALL',
      clearDates: true,
      sortColumn: 'created_at',
      sortAscending: false,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);

    try {
      final deliveries = await _fetchCurrentDeliveries(nextState);
      emit(state.copyWith(deliveriesResult: deliveries, isTableLoading: false));
    } catch (_) {
      emit(state.copyWith(isTableLoading: false));
    }
  }

  Future<void> _onSortChanged(
    AdminDeliverySortChanged event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    final isSameColumn = state.sortColumn == event.sortColumn;
    final nextAscending = isSameColumn ? !state.sortAscending : true;

    final nextState = state.copyWith(
      sortColumn: event.sortColumn,
      sortAscending: nextAscending,
      isTableLoading: true,
    );
    emit(nextState);

    try {
      final deliveries = await _fetchCurrentDeliveries(nextState);
      emit(state.copyWith(deliveriesResult: deliveries, isTableLoading: false));
    } catch (_) {
      emit(state.copyWith(isTableLoading: false));
    }
  }

  Future<void> _onPageChanged(
    AdminDeliveryPageChanged event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    final nextState = state.copyWith(
      currentPage: event.page,
      isTableLoading: true,
    );
    emit(nextState);

    try {
      final deliveries = await _fetchCurrentDeliveries(nextState);
      emit(state.copyWith(deliveriesResult: deliveries, isTableLoading: false));
    } catch (_) {
      emit(state.copyWith(isTableLoading: false));
    }
  }

  Future<void> _onDetailRequested(
    AdminDeliveryDetailRequested event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearActionErrorMessage: true,
        clearActionSuccessMessage: true,
      ),
    );

    try {
      final detail = await repository.getDeliveryDetail(event.shipmentId);
      emit(state.copyWith(selectedDetail: detail, isDetailLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          actionErrorMessage: 'Gagal memuat detail pengiriman: ${e.toString()}',
        ),
      );
    }
  }

  void _onDetailDismissed(
    AdminDeliveryDetailDismissed event,
    Emitter<AdminDeliveryState> emit,
  ) {
    emit(state.copyWith(clearSelectedDetail: true));
  }

  Future<void> _onConfirmOrderRequested(
    AdminDeliveryConfirmOrderRequested event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionErrorMessage: true,
        clearActionSuccessMessage: true,
      ),
    );

    try {
      await repository.confirmShipmentOrder(
        shipmentId: event.shipmentId,
        notes: event.notes,
      );

      final deliveries = await _fetchCurrentDeliveries(state);
      var updatedDetail = state.selectedDetail;
      if (updatedDetail != null && updatedDetail.id == event.shipmentId) {
        updatedDetail = await repository.getDeliveryDetail(event.shipmentId);
      }

      emit(
        state.copyWith(
          deliveriesResult: deliveries,
          selectedDetail: updatedDetail,
          isActionInProgress: false,
          actionSuccessMessage: 'Pesanan pengiriman berhasil dikonfirmasi dan tercatat pada kronologi tracking.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onAssignCourierRequested(
    AdminDeliveryAssignCourierRequested event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionErrorMessage: true,
        clearActionSuccessMessage: true,
      ),
    );

    try {
      await repository.assignCourierToShipment(
        shipmentId: event.shipmentId,
        courierId: event.courierId,
        notes: event.notes,
      );

      final deliveries = await _fetchCurrentDeliveries(state);
      final couriers = await repository.getAssignableCouriers();
      var updatedDetail = state.selectedDetail;
      if (updatedDetail != null && updatedDetail.id == event.shipmentId) {
        updatedDetail = await repository.getDeliveryDetail(event.shipmentId);
      }

      emit(
        state.copyWith(
          deliveriesResult: deliveries,
          couriers: couriers,
          selectedDetail: updatedDetail,
          isActionInProgress: false,
          actionSuccessMessage: 'Penugasan kurir berhasil disimpan ke t_shipment_assignments dan dicatat di t_shipment_tracking.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateStatusRequested(
    AdminDeliveryUpdateStatusRequested event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionErrorMessage: true,
        clearActionSuccessMessage: true,
      ),
    );

    try {
      await repository.updateShipmentStatus(
        shipmentId: event.shipmentId,
        targetStatusCode: event.targetStatusCode,
        lokasiNama: event.lokasiNama,
        notes: event.notes,
      );

      final deliveries = await _fetchCurrentDeliveries(state);
      final couriers = await repository.getAssignableCouriers();
      var updatedDetail = state.selectedDetail;
      if (updatedDetail != null && updatedDetail.id == event.shipmentId) {
        updatedDetail = await repository.getDeliveryDetail(event.shipmentId);
      }

      emit(
        state.copyWith(
          deliveriesResult: deliveries,
          couriers: couriers,
          selectedDetail: updatedDetail,
          isActionInProgress: false,
          actionSuccessMessage:
              'Status pengiriman berhasil diperbarui menjadi ${event.targetStatusCode}.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onHandleFailedRequested(
    AdminDeliveryHandleFailedRequested event,
    Emitter<AdminDeliveryState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionErrorMessage: true,
        clearActionSuccessMessage: true,
      ),
    );

    try {
      await repository.handleFailedDelivery(
        shipmentId: event.shipmentId,
        resolutionAction: event.resolutionAction,
        reassignCourierId: event.reassignCourierId,
        notes: event.notes,
      );

      final deliveries = await _fetchCurrentDeliveries(state);
      final couriers = await repository.getAssignableCouriers();
      var updatedDetail = state.selectedDetail;
      if (updatedDetail != null && updatedDetail.id == event.shipmentId) {
        updatedDetail = await repository.getDeliveryDetail(event.shipmentId);
      }

      emit(
        state.copyWith(
          deliveriesResult: deliveries,
          couriers: couriers,
          selectedDetail: updatedDetail,
          isActionInProgress: false,
          actionSuccessMessage: 'Penanganan pengiriman gagal berhasil diproses dan tercatat di kronologi.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onClearNotification(
    AdminDeliveryClearNotification event,
    Emitter<AdminDeliveryState> emit,
  ) {
    emit(
      state.copyWith(
        clearActionErrorMessage: true,
        clearActionSuccessMessage: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    return super.close();
  }
}
