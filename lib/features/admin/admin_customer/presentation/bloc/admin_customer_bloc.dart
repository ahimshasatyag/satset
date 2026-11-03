import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/admin_customer_remote_datasource.dart';
import '../../domain/repositories/admin_customer_repository.dart';
import '../../domain/usecases/get_admin_customer_detail_usecase.dart';
import '../../domain/usecases/get_admin_customers_usecase.dart';
import '../../domain/usecases/toggle_customer_verification_usecase.dart';
import '../../domain/usecases/update_customer_profile_usecase.dart';
import 'admin_customer_event.dart';
import 'admin_customer_state.dart';

class AdminCustomerBloc extends Bloc<AdminCustomerEvent, AdminCustomerState> {
  final AdminCustomerRepository repository;
  final AdminCustomerRemoteDataSource remoteDataSource;
  late final GetAdminCustomersUseCase _getCustomersUseCase;
  late final GetAdminCustomerDetailUseCase _getCustomerDetailUseCase;
  late final UpdateCustomerProfileUseCase _updateProfileUseCase;
  late final ToggleCustomerVerificationUseCase _toggleVerificationUseCase;

  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeDebounce;

  AdminCustomerBloc({
    required this.repository,
    required this.remoteDataSource,
  }) : super(const AdminCustomerState()) {
    _getCustomersUseCase = GetAdminCustomersUseCase(repository);
    _getCustomerDetailUseCase = GetAdminCustomerDetailUseCase(repository);
    _updateProfileUseCase = UpdateCustomerProfileUseCase(repository);
    _toggleVerificationUseCase = ToggleCustomerVerificationUseCase(repository);

    on<AdminCustomerStarted>(_onStarted);
    on<AdminCustomerRefreshed>(_onRefreshed);
    on<AdminCustomerRealtimeTriggered>(_onRealtimeTriggered);
    on<AdminCustomerSearchChanged>(_onSearchChanged);
    on<AdminCustomerFiltersUpdated>(_onFiltersUpdated);
    on<AdminCustomerFiltersReset>(_onFiltersReset);
    on<AdminCustomerSortChanged>(_onSortChanged);
    on<AdminCustomerPageChanged>(_onPageChanged);
    on<AdminCustomerDetailRequested>(_onDetailRequested);
    on<AdminCustomerDetailDismissed>(_onDetailDismissed);
    on<AdminCustomerUpdateRequested>(_onUpdateRequested);
    on<AdminCustomerToggleVerificationRequested>(_onToggleVerificationRequested);
    on<AdminCustomerClearNotification>(_onClearNotification);
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = remoteDataSource.subscribeToRealtimeUpdates(
      onDataChanged: () {
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(milliseconds: 700), () {
          if (!isClosed) {
            add(const AdminCustomerRealtimeTriggered());
          }
        });
      },
    );
  }

  Future<void> _onStarted(
    AdminCustomerStarted event,
    Emitter<AdminCustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminCustomerStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final isAuthorized = await repository.verifyAdminAccess();
      if (!isAuthorized) {
        emit(
          state.copyWith(
            status: AdminCustomerStatus.unauthorized,
            errorMessage:
                'Akses Ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang memiliki izin mengelola data customer.',
          ),
        );
        return;
      }

      final result = await _getCustomersUseCase(
        searchQuery: state.searchQuery,
        verificationFilter: state.verificationFilter,
        startDate: state.startDate,
        endDate: state.endDate,
        sortColumn: state.sortColumn,
        sortAscending: state.sortAscending,
        page: state.currentPage,
      );

      _setupRealtimeSubscription();

      emit(
        state.copyWith(
          status: AdminCustomerStatus.loaded,
          customersResult: result,
          isTableLoading: false,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminCustomerStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _reloadTable(
    Emitter<AdminCustomerState> emit, {
    int? pageOverride,
    bool silent = false,
  }) async {
    if (!silent) {
      emit(state.copyWith(isTableLoading: true));
    }

    try {
      final targetPage = pageOverride ?? state.currentPage;
      final result = await _getCustomersUseCase(
        searchQuery: state.searchQuery,
        verificationFilter: state.verificationFilter,
        startDate: state.startDate,
        endDate: state.endDate,
        sortColumn: state.sortColumn,
        sortAscending: state.sortAscending,
        page: targetPage,
      );

      AdminCustomerState nextState = state.copyWith(
        customersResult: result,
        currentPage: targetPage,
        isTableLoading: false,
        isRefreshing: false,
      );

      if (state.selectedDetail != null) {
        try {
          final updatedDetail = await _getCustomerDetailUseCase(
            state.selectedDetail!.customer.id,
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
    AdminCustomerRefreshed event,
    Emitter<AdminCustomerState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    await _reloadTable(emit, silent: true);
  }

  Future<void> _onRealtimeTriggered(
    AdminCustomerRealtimeTriggered event,
    Emitter<AdminCustomerState> emit,
  ) async {
    if (state.status != AdminCustomerStatus.loaded) return;
    await _reloadTable(emit, silent: true);
  }

  Future<void> _onSearchChanged(
    AdminCustomerSearchChanged event,
    Emitter<AdminCustomerState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query, currentPage: 1));
    await _reloadTable(emit, pageOverride: 1);
  }

  Future<void> _onFiltersUpdated(
    AdminCustomerFiltersUpdated event,
    Emitter<AdminCustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        verificationFilter:
            event.verificationFilter ?? state.verificationFilter,
        startDate: event.startDate,
        endDate: event.endDate,
        clearDates: event.clearDates,
        currentPage: 1,
      ),
    );
    await _reloadTable(emit, pageOverride: 1);
  }

  Future<void> _onFiltersReset(
    AdminCustomerFiltersReset event,
    Emitter<AdminCustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: '',
        verificationFilter: 'ALL',
        clearDates: true,
        sortColumn: 'created_at',
        sortAscending: false,
        currentPage: 1,
      ),
    );
    await _reloadTable(emit, pageOverride: 1);
  }

  Future<void> _onSortChanged(
    AdminCustomerSortChanged event,
    Emitter<AdminCustomerState> emit,
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
    AdminCustomerPageChanged event,
    Emitter<AdminCustomerState> emit,
  ) async {
    emit(state.copyWith(currentPage: event.page));
    await _reloadTable(emit, pageOverride: event.page);
  }

  Future<void> _onDetailRequested(
    AdminCustomerDetailRequested event,
    Emitter<AdminCustomerState> emit,
  ) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearActionMessages: true,
      ),
    );
    try {
      final detail = await _getCustomerDetailUseCase(event.customerId);
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
    AdminCustomerDetailDismissed event,
    Emitter<AdminCustomerState> emit,
  ) {
    emit(state.copyWith(clearSelectedDetail: true));
  }

  Future<void> _onUpdateRequested(
    AdminCustomerUpdateRequested event,
    Emitter<AdminCustomerState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionMessages: true,
      ),
    );

    try {
      final updated = await _updateProfileUseCase(
        customerId: event.customerId,
        namaLengkap: event.namaLengkap,
        email: event.email,
        noHp: event.noHp,
        alamatLengkap: event.alamatLengkap,
        idProvinsi: event.idProvinsi,
        idKabkot: event.idKabkot,
        idKecamatan: event.idKecamatan,
        idKelurahan: event.idKelurahan,
        latitude: event.latitude,
        longitude: event.longitude,
        emailVerified: event.emailVerified,
      );

      emit(
        state.copyWith(
          isActionInProgress: false,
          actionSuccessMessage:
              'Profil customer "${updated.namaLengkap}" (ID #${updated.id}) berhasil diperbarui.',
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

  Future<void> _onToggleVerificationRequested(
    AdminCustomerToggleVerificationRequested event,
    Emitter<AdminCustomerState> emit,
  ) async {
    if (state.isActionInProgress) return;
    emit(
      state.copyWith(
        isActionInProgress: true,
        clearActionMessages: true,
      ),
    );

    try {
      await _toggleVerificationUseCase(
        customerId: event.customerId,
        emailVerified: event.emailVerified,
      );

      emit(
        state.copyWith(
          isActionInProgress: false,
          actionSuccessMessage: event.emailVerified
              ? 'Status email customer berhasil ditetapkan menjadi Terverifikasi.'
              : 'Status verifikasi email customer berhasil dicabut.',
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
    AdminCustomerClearNotification event,
    Emitter<AdminCustomerState> emit,
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

