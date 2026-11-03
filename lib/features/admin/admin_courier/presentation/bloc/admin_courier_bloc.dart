import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/admin_courier_remote_datasource.dart';
import '../../domain/repositories/admin_courier_repository.dart';
import '../../domain/usecases/create_courier_account_usecase.dart';
import '../../domain/usecases/get_admin_courier_detail_usecase.dart';
import '../../domain/usecases/get_admin_couriers_usecase.dart';
import '../../domain/usecases/toggle_courier_status_usecase.dart';
import '../../domain/usecases/unassign_courier_task_usecase.dart';
import '../../domain/usecases/update_courier_profile_usecase.dart';
import 'admin_courier_event.dart';
import 'admin_courier_state.dart';

class AdminCourierBloc extends Bloc<AdminCourierEvent, AdminCourierState> {
  final AdminCourierRepository repository;
  final AdminCourierRemoteDataSource remoteDataSource;
  late final GetAdminCouriersUseCase _getCouriersUseCase;
  late final GetAdminCourierDetailUseCase _getCourierDetailUseCase;
  late final CreateCourierAccountUseCase _createCourierUseCase;
  late final UpdateCourierProfileUseCase _updateCourierUseCase;
  late final ToggleCourierStatusUseCase _toggleStatusUseCase;
  late final UnassignCourierTaskUseCase _unassignTaskUseCase;

  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeDebounce;

  AdminCourierBloc({
    required this.repository,
    required this.remoteDataSource,
  }) : super(const AdminCourierState()) {
    _getCouriersUseCase = GetAdminCouriersUseCase(repository);
    _getCourierDetailUseCase = GetAdminCourierDetailUseCase(repository);
    _createCourierUseCase = CreateCourierAccountUseCase(repository);
    _updateCourierUseCase = UpdateCourierProfileUseCase(repository);
    _toggleStatusUseCase = ToggleCourierStatusUseCase(repository);
    _unassignTaskUseCase = UnassignCourierTaskUseCase(repository);

    on<AdminCourierStarted>(_onStarted);
    on<AdminCourierRefreshed>(_onRefreshed);
    on<AdminCourierRealtimeTriggered>(_onRealtimeTriggered);
    on<AdminCourierSearchChanged>(_onSearchChanged);
    on<AdminCourierFiltersUpdated>(_onFiltersUpdated);
    on<AdminCourierFiltersReset>(_onFiltersReset);
    on<AdminCourierSortChanged>(_onSortChanged);
    on<AdminCourierPageChanged>(_onPageChanged);
    on<AdminCourierDetailRequested>(_onDetailRequested);
    on<AdminCourierDetailDismissed>(_onDetailDismissed);
    on<AdminCourierCreateRequested>(_onCreateRequested);
    on<AdminCourierUpdateRequested>(_onUpdateRequested);
    on<AdminCourierToggleStatusRequested>(_onToggleStatusRequested);
    on<AdminCourierUnassignTaskRequested>(_onUnassignTaskRequested);
    on<AdminCourierClearNotification>(_onClearNotification);
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = remoteDataSource.subscribeToRealtimeUpdates(
      onDataChanged: () {
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(milliseconds: 700), () {
          if (!isClosed) {
            add(const AdminCourierRealtimeTriggered());
          }
        });
      },
    );
  }

  Future<void> _onStarted(
    AdminCourierStarted event,
    Emitter<AdminCourierState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminCourierStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final isAuthorized = await repository.verifyAdminAccess();
      if (!isAuthorized) {
        emit(
          state.copyWith(
            status: AdminCourierStatus.unauthorized,
            errorMessage:
                'Akses Ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang memiliki izin mengelola data kurir.',
          ),
        );
        return;
      }

      final result = await _getCouriersUseCase(
        searchQuery: state.searchQuery,
        accountStatusFilter: state.accountStatusFilter,
        activityStatusFilter: state.activityStatusFilter,
        sortColumn: state.sortColumn,
        sortAscending: state.sortAscending,
        page: state.currentPage,
      );

      _setupRealtimeSubscription();

      emit(
        state.copyWith(
          status: AdminCourierStatus.loaded,
          couriersResult: result,
          isTableLoading: false,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminCourierStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _reloadTable(
    Emitter<AdminCourierState> emit, {
    int? pageOverride,
    bool silent = false,
  }) async {
    if (!silent) {
      emit(state.copyWith(isTableLoading: true));
    }

    try {
      final targetPage = pageOverride ?? state.currentPage;
      final result = await _getCouriersUseCase(
        searchQuery: state.searchQuery,
        accountStatusFilter: state.accountStatusFilter,
        activityStatusFilter: state.activityStatusFilter,
        sortColumn: state.sortColumn,
        sortAscending: state.sortAscending,
        page: targetPage,
      );

      AdminCourierState nextState = state.copyWith(
        couriersResult: result,
        currentPage: targetPage,
        isTableLoading: false,
        isRefreshing: false,
      );

      if (state.selectedDetail != null) {
        try {
          final updatedDetail = await _getCourierDetailUseCase(
            state.selectedDetail!.courier.id,
          );
          nextState = nextState.copyWith(selectedDetail: updatedDetail);
        } catch (_) {}
      }

      emit(nextState);
    } catch (e) {
      emit(
        state.copyWith(
          isTableLoading: false,
          isRefreshing: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    AdminCourierRefreshed event,
    Emitter<AdminCourierState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _reloadTable(emit, silent: true);
  }

  Future<void> _onRealtimeTriggered(
    AdminCourierRealtimeTriggered event,
    Emitter<AdminCourierState> emit,
  ) async {
    if (state.status != AdminCourierStatus.loaded) return;
    await _reloadTable(emit, silent: true);
  }

  Future<void> _onSearchChanged(
    AdminCourierSearchChanged event,
    Emitter<AdminCourierState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query, currentPage: 1));
    await _reloadTable(emit, pageOverride: 1);
  }

  Future<void> _onFiltersUpdated(
    AdminCourierFiltersUpdated event,
    Emitter<AdminCourierState> emit,
  ) async {
    emit(
      state.copyWith(
        accountStatusFilter:
            event.accountStatusFilter ?? state.accountStatusFilter,
        activityStatusFilter:
            event.activityStatusFilter ?? state.activityStatusFilter,
        currentPage: 1,
      ),
    );
    await _reloadTable(emit, pageOverride: 1);
  }

  Future<void> _onFiltersReset(
    AdminCourierFiltersReset event,
    Emitter<AdminCourierState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: '',
        accountStatusFilter: 'ALL',
        activityStatusFilter: 'ALL',
        sortColumn: 'created_at',
        sortAscending: false,
        currentPage: 1,
      ),
    );
    await _reloadTable(emit, pageOverride: 1);
  }

  Future<void> _onSortChanged(
    AdminCourierSortChanged event,
    Emitter<AdminCourierState> emit,
  ) async {
    final isSameCol = state.sortColumn == event.sortColumn;
    final nextAsc = isSameCol ? !state.sortAscending : true;
    emit(
      state.copyWith(
        sortColumn: event.sortColumn,
        sortAscending: nextAsc,
        currentPage: 1,
      ),
    );
    await _reloadTable(emit, pageOverride: 1);
  }

  Future<void> _onPageChanged(
    AdminCourierPageChanged event,
    Emitter<AdminCourierState> emit,
  ) async {
    emit(state.copyWith(currentPage: event.page));
    await _reloadTable(emit, pageOverride: event.page);
  }

  Future<void> _onDetailRequested(
    AdminCourierDetailRequested event,
    Emitter<AdminCourierState> emit,
  ) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearActionMessages: true,
      ),
    );
    try {
      final detail = await _getCourierDetailUseCase(event.courierId);
      emit(
        state.copyWith(
          isDetailLoading: false,
          selectedDetail: detail,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isDetailLoading: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onDetailDismissed(
    AdminCourierDetailDismissed event,
    Emitter<AdminCourierState> emit,
  ) {
    emit(state.copyWith(clearSelectedDetail: true));
  }

  Future<void> _onCreateRequested(
    AdminCourierCreateRequested event,
    Emitter<AdminCourierState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionMessages: true,
      ),
    );

    try {
      final created = await _createCourierUseCase(
        namaLengkap: event.namaLengkap,
        email: event.email,
        noHp: event.noHp,
        password: event.password,
        employeeCode: event.employeeCode,
        alamatLengkap: event.alamatLengkap,
        fotoUrl: event.fotoUrl,
        isActive: event.isActive,
      );

      emit(
        state.copyWith(
          isActionInProgress: false,
          actionSuccessMessage:
              'Kurir "${created.namaLengkap}" (${created.employeeCode}) berhasil ditambahkan dengan role Kurir (id_users_role = 2).',
        ),
      );
      await _reloadTable(emit, silent: true);
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
    AdminCourierUpdateRequested event,
    Emitter<AdminCourierState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionMessages: true,
      ),
    );

    try {
      final updated = await _updateCourierUseCase(
        courierId: event.courierId,
        namaLengkap: event.namaLengkap,
        email: event.email,
        noHp: event.noHp,
        alamatLengkap: event.alamatLengkap,
        fotoUrl: event.fotoUrl,
        newPassword: event.newPassword,
        isActive: event.isActive,
      );

      emit(
        state.copyWith(
          isActionInProgress: false,
          actionSuccessMessage:
              'Profil kurir "${updated.namaLengkap}" (${updated.employeeCode}) berhasil diperbarui.',
        ),
      );
      await _reloadTable(emit, silent: true);
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
    AdminCourierToggleStatusRequested event,
    Emitter<AdminCourierState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionMessages: true,
      ),
    );

    try {
      await _toggleStatusUseCase(
        courierId: event.courierId,
        isActive: event.isActive,
      );

      emit(
        state.copyWith(
          isActionInProgress: false,
          actionSuccessMessage: event.isActive
              ? 'Akun kurir berhasil diaktifkan.'
              : 'Akun kurir berhasil dinonaktifkan.',
        ),
      );
      await _reloadTable(emit, silent: true);
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUnassignTaskRequested(
    AdminCourierUnassignTaskRequested event,
    Emitter<AdminCourierState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionMessages: true,
      ),
    );

    try {
      await _unassignTaskUseCase(
        assignmentId: event.assignmentId,
        shipmentId: event.shipmentId,
        reason: event.reason,
      );

      emit(
        state.copyWith(
          isActionInProgress: false,
          actionSuccessMessage:
              'Penugasan pengiriman berhasil dilepas dari kurir dan dicatat pada kronologi tracking.',
        ),
      );
      await _reloadTable(emit, silent: true);
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
    AdminCourierClearNotification event,
    Emitter<AdminCourierState> emit,
  ) {
    emit(state.copyWith(clearActionMessages: true));
  }

  @override
  Future<void> close() {
    _realtimeDebounce?.cancel();
    _realtimeChannel?.unsubscribe();
    return super.close();
  }
}

