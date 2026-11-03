import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/admin_service_type_remote_datasource.dart';
import '../../domain/repositories/admin_service_type_repository.dart';
import '../../domain/usecases/create_service_type_usecase.dart';
import '../../domain/usecases/delete_service_type_usecase.dart';
import '../../domain/usecases/get_admin_service_type_detail_usecase.dart';
import '../../domain/usecases/get_admin_service_types_usecase.dart';
import '../../domain/usecases/toggle_service_type_status_usecase.dart';
import '../../domain/usecases/update_service_type_usecase.dart';
import 'admin_service_type_event.dart';
import 'admin_service_type_state.dart';

class AdminServiceTypeBloc
    extends Bloc<AdminServiceTypeEvent, AdminServiceTypeState> {
  final AdminServiceTypeRepository repository;
  final AdminServiceTypeRemoteDataSource remoteDataSource;

  late final GetAdminServiceTypesUseCase _getAdminServiceTypesUseCase;
  late final GetAdminServiceTypeDetailUseCase _getAdminServiceTypeDetailUseCase;
  late final CreateServiceTypeUseCase _createServiceTypeUseCase;
  late final UpdateServiceTypeUseCase _updateServiceTypeUseCase;
  late final ToggleServiceTypeStatusUseCase _toggleServiceTypeStatusUseCase;
  late final DeleteServiceTypeUseCase _deleteServiceTypeUseCase;

  RealtimeChannel? _realtimeChannel;

  AdminServiceTypeBloc({
    required this.repository,
    required this.remoteDataSource,
  }) : super(const AdminServiceTypeState()) {
    _getAdminServiceTypesUseCase = GetAdminServiceTypesUseCase(repository);
    _getAdminServiceTypeDetailUseCase =
        GetAdminServiceTypeDetailUseCase(repository);
    _createServiceTypeUseCase = CreateServiceTypeUseCase(repository);
    _updateServiceTypeUseCase = UpdateServiceTypeUseCase(repository);
    _toggleServiceTypeStatusUseCase = ToggleServiceTypeStatusUseCase(repository);
    _deleteServiceTypeUseCase = DeleteServiceTypeUseCase(repository);

    on<AdminServiceTypeStarted>(_onStarted);
    on<AdminServiceTypeRefreshed>(_onRefreshed);
    on<AdminServiceTypeRealtimeUpdated>(_onRealtimeUpdated);
    on<AdminServiceTypeSearchChanged>(_onSearchChanged);
    on<AdminServiceTypeFilterChanged>(_onFilterChanged);
    on<AdminServiceTypeFiltersReset>(_onFiltersReset);
    on<AdminServiceTypeSortChanged>(_onSortChanged);
    on<AdminServiceTypePageChanged>(_onPageChanged);
    on<AdminServiceTypeDetailRequested>(_onDetailRequested);
    on<AdminServiceTypeDetailDismissed>(_onDetailDismissed);
    on<AdminServiceTypeCreateRequested>(_onCreateRequested);
    on<AdminServiceTypeUpdateRequested>(_onUpdateRequested);
    on<AdminServiceTypeToggleStatusRequested>(_onToggleStatusRequested);
    on<AdminServiceTypeDeleteRequested>(_onDeleteRequested);
    on<AdminServiceTypeClearNotification>(_onClearNotification);
  }

  Future<void> _onStarted(
    AdminServiceTypeStarted event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    emit(state.copyWith(status: AdminServiceTypeStatus.loading));

    try {
      final hasAccess = await repository.verifyAdminAccess();
      if (!hasAccess) {
        emit(
          state.copyWith(
            status: AdminServiceTypeStatus.unauthorized,
            errorMessage:
                'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang diizinkan mengakses halaman Manajemen Jenis Layanan.',
          ),
        );
        return;
      }

      final result = await _fetchServices(state);
      emit(
        state.copyWith(
          status: AdminServiceTypeStatus.loaded,
          servicesResult: result,
        ),
      );

      _subscribeRealtime();
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminServiceTypeStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _subscribeRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = remoteDataSource.subscribeToRealtimeUpdates(
      onDataChanged: () {
        if (!isClosed) {
          add(const AdminServiceTypeRealtimeUpdated());
        }
      },
    );
  }

  Future<void> _onRefreshed(
    AdminServiceTypeRefreshed event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final result = await _fetchServices(state);
      emit(
        state.copyWith(
          status: AdminServiceTypeStatus.loaded,
          servicesResult: result,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          actionErrorMessage:
              'Gagal memperbarui data jenis layanan: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> _onRealtimeUpdated(
    AdminServiceTypeRealtimeUpdated event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    if (state.status != AdminServiceTypeStatus.loaded) return;
    try {
      final result = await _fetchServices(state);
      var nextState = state.copyWith(servicesResult: result);
      if (state.selectedDetail != null) {
        final refreshedDetail = await _getAdminServiceTypeDetailUseCase(
          state.selectedDetail!.serviceType.id,
        );
        nextState = nextState.copyWith(selectedDetail: refreshedDetail);
      }
      emit(nextState);
    } catch (_) {}
  }

  Future<void> _onSearchChanged(
    AdminServiceTypeSearchChanged event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    final nextState = state.copyWith(
      searchQuery: event.searchQuery,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onFilterChanged(
    AdminServiceTypeFilterChanged event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    final nextState = state.copyWith(
      statusFilter: event.statusFilter,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onFiltersReset(
    AdminServiceTypeFiltersReset event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    final nextState = state.copyWith(
      searchQuery: '',
      statusFilter: 'ALL',
      sortColumn: 'id',
      sortAscending: true,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onSortChanged(
    AdminServiceTypeSortChanged event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    final isSameCol = state.sortColumn == event.sortColumn;
    final nextAsc = isSameCol ? !state.sortAscending : true;
    final nextState = state.copyWith(
      sortColumn: event.sortColumn,
      sortAscending: nextAsc,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onPageChanged(
    AdminServiceTypePageChanged event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    final nextState = state.copyWith(
      currentPage: event.page,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onDetailRequested(
    AdminServiceTypeDetailRequested event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    emit(state.copyWith(isDetailLoading: true, clearNotifications: true));
    try {
      final detail = await _getAdminServiceTypeDetailUseCase(event.serviceId);
      emit(
        state.copyWith(
          selectedDetail: detail,
          isDetailLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          actionErrorMessage:
              'Gagal memuat detail jenis layanan: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  void _onDetailDismissed(
    AdminServiceTypeDetailDismissed event,
    Emitter<AdminServiceTypeState> emit,
  ) {
    emit(state.copyWith(clearSelectedDetail: true));
  }

  Future<void> _onCreateRequested(
    AdminServiceTypeCreateRequested event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearNotifications: true));
    try {
      final created = await _createServiceTypeUseCase(
        kode: event.kode,
        namaLayanan: event.namaLayanan,
        estimasiHariMin: event.estimasiHariMin,
        estimasiHariMax: event.estimasiHariMax,
        deskripsi: event.deskripsi,
        baseTariffPerKg: event.baseTariffPerKg,
        isActive: event.isActive,
      );

      final result = await _fetchServices(state);
      emit(
        state.copyWith(
          servicesResult: result,
          isActionInProgress: false,
          actionSuccessMessage:
              'Jenis layanan "${created.namaLayanan}" (${created.kode}) berhasil ditambahkan ke m_service_types.',
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

  Future<void> _onUpdateRequested(
    AdminServiceTypeUpdateRequested event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearNotifications: true));
    try {
      final updated = await _updateServiceTypeUseCase(
        serviceId: event.serviceId,
        kode: event.kode,
        namaLayanan: event.namaLayanan,
        estimasiHariMin: event.estimasiHariMin,
        estimasiHariMax: event.estimasiHariMax,
        deskripsi: event.deskripsi,
        baseTariffPerKg: event.baseTariffPerKg,
        isActive: event.isActive,
      );

      final result = await _fetchServices(state);
      var nextState = state.copyWith(
        servicesResult: result,
        isActionInProgress: false,
        actionSuccessMessage:
            'Jenis layanan "${updated.namaLayanan}" (${updated.kode}) berhasil diperbarui.',
      );

      if (state.selectedDetail?.serviceType.id == event.serviceId) {
        final refreshedDetail =
            await _getAdminServiceTypeDetailUseCase(event.serviceId);
        nextState = nextState.copyWith(selectedDetail: refreshedDetail);
      }

      emit(nextState);
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onToggleStatusRequested(
    AdminServiceTypeToggleStatusRequested event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearNotifications: true));
    try {
      await _toggleServiceTypeStatusUseCase(
        serviceId: event.serviceId,
        isActive: event.isActive,
      );

      final result = await _fetchServices(state);
      var nextState = state.copyWith(
        servicesResult: result,
        isActionInProgress: false,
        actionSuccessMessage: event.isActive
            ? 'Jenis layanan berhasil diaktifkan kembali dan tersedia pada pilihan pesanan customer.'
            : 'Jenis layanan berhasil dinonaktifkan (disembunyikan dari pesanan baru, namun histori pengiriman lama tetap terjaga).',
      );

      if (state.selectedDetail?.serviceType.id == event.serviceId) {
        final refreshedDetail =
            await _getAdminServiceTypeDetailUseCase(event.serviceId);
        nextState = nextState.copyWith(selectedDetail: refreshedDetail);
      }

      emit(nextState);
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    AdminServiceTypeDeleteRequested event,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearNotifications: true));
    try {
      await _deleteServiceTypeUseCase(event.serviceId);

      final result = await _fetchServices(state);
      emit(
        state.copyWith(
          servicesResult: result,
          clearSelectedDetail:
              state.selectedDetail?.serviceType.id == event.serviceId,
          isActionInProgress: false,
          actionSuccessMessage:
              'Jenis layanan yang belum memiliki transaksi pengiriman berhasil dihapus dari m_service_types.',
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
    AdminServiceTypeClearNotification event,
    Emitter<AdminServiceTypeState> emit,
  ) {
    emit(state.copyWith(clearNotifications: true));
  }

  Future<void> _reloadTable(
    AdminServiceTypeState targetState,
    Emitter<AdminServiceTypeState> emit,
  ) async {
    try {
      final result = await _fetchServices(targetState);
      emit(
        targetState.copyWith(
          servicesResult: result,
          isTableLoading: false,
        ),
      );
    } catch (e) {
      emit(
        targetState.copyWith(
          isTableLoading: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<dynamic> _fetchServices(AdminServiceTypeState s) {
    return _getAdminServiceTypesUseCase(
      searchQuery: s.searchQuery,
      statusFilter: s.statusFilter,
      sortColumn: s.sortColumn,
      sortAscending: s.sortAscending,
      page: s.currentPage,
      pageSize: s.pageSize,
    );
  }

  @override
  Future<void> close() {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }
}

