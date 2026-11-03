import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/admin_payment_remote_datasource.dart';
import '../../domain/repositories/admin_payment_repository.dart';
import '../../domain/usecases/confirm_cod_payment_usecase.dart';
import '../../domain/usecases/get_admin_payment_detail_usecase.dart';
import '../../domain/usecases/get_admin_payments_usecase.dart';
import '../../domain/usecases/reconcile_payment_status_usecase.dart';
import 'admin_payment_event.dart';
import 'admin_payment_state.dart';

class AdminPaymentBloc extends Bloc<AdminPaymentEvent, AdminPaymentState> {
  final AdminPaymentRepository repository;
  final AdminPaymentRemoteDataSource remoteDataSource;
  late final GetAdminPaymentsUseCase _getAdminPaymentsUseCase;
  late final GetAdminPaymentDetailUseCase _getAdminPaymentDetailUseCase;
  late final ReconcilePaymentStatusUseCase _reconcilePaymentStatusUseCase;
  late final ConfirmCodPaymentUseCase _confirmCodPaymentUseCase;

  RealtimeChannel? _realtimeChannel;

  AdminPaymentBloc({
    required this.repository,
    required this.remoteDataSource,
  }) : super(const AdminPaymentState()) {
    _getAdminPaymentsUseCase = GetAdminPaymentsUseCase(repository);
    _getAdminPaymentDetailUseCase = GetAdminPaymentDetailUseCase(repository);
    _reconcilePaymentStatusUseCase = ReconcilePaymentStatusUseCase(repository);
    _confirmCodPaymentUseCase = ConfirmCodPaymentUseCase(repository);

    on<AdminPaymentStarted>(_onStarted);
    on<AdminPaymentRefreshed>(_onRefreshed);
    on<AdminPaymentRealtimeUpdated>(_onRealtimeUpdated);
    on<AdminPaymentTabSelected>(_onTabSelected);
    on<AdminPaymentPeriodChanged>(_onPeriodChanged);
    on<AdminPaymentSearchChanged>(_onSearchChanged);
    on<AdminPaymentFiltersUpdated>(_onFiltersUpdated);
    on<AdminPaymentFiltersReset>(_onFiltersReset);
    on<AdminPaymentSortChanged>(_onSortChanged);
    on<AdminPaymentPageChanged>(_onPageChanged);
    on<AdminPaymentDetailRequested>(_onDetailRequested);
    on<AdminPaymentDetailDismissed>(_onDetailDismissed);
    on<AdminPaymentReconcileRequested>(_onReconcileRequested);
    on<AdminPaymentConfirmCodRequested>(_onConfirmCodRequested);
    on<AdminPaymentClearNotification>(_onClearNotification);
  }

  Future<void> _onStarted(
    AdminPaymentStarted event,
    Emitter<AdminPaymentState> emit,
  ) async {
    emit(state.copyWith(status: AdminPaymentStatus.loading));

    try {
      final hasAccess = await repository.verifyAdminAccess();
      if (!hasAccess) {
        emit(
          state.copyWith(
            status: AdminPaymentStatus.unauthorized,
            errorMessage:
                'Akses ditolak: Hanya Administrator resmi (m_employee.id_users_role = 1) yang diizinkan mengakses halaman Manajemen Pembayaran.',
          ),
        );
        return;
      }

      final result = await _fetchPayments(state);
      emit(
        state.copyWith(
          status: AdminPaymentStatus.loaded,
          paymentsResult: result,
        ),
      );

      _subscribeRealtime();
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminPaymentStatus.error,
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
          add(const AdminPaymentRealtimeUpdated());
        }
      },
    );
  }

  Future<void> _onRefreshed(
    AdminPaymentRefreshed event,
    Emitter<AdminPaymentState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final result = await _fetchPayments(state);
      emit(
        state.copyWith(
          status: AdminPaymentStatus.loaded,
          paymentsResult: result,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          actionErrorMessage:
              'Gagal memperbarui data pembayaran: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> _onRealtimeUpdated(
    AdminPaymentRealtimeUpdated event,
    Emitter<AdminPaymentState> emit,
  ) async {
    if (state.status != AdminPaymentStatus.loaded) return;
    try {
      final result = await _fetchPayments(state);
      var nextState = state.copyWith(paymentsResult: result);
      if (state.selectedDetail != null) {
        final refreshedDetail = await _getAdminPaymentDetailUseCase(
          state.selectedDetail!.payment.id,
        );
        nextState = nextState.copyWith(selectedDetail: refreshedDetail);
      }
      emit(nextState);
    } catch (_) {}
  }

  Future<void> _onTabSelected(
    AdminPaymentTabSelected event,
    Emitter<AdminPaymentState> emit,
  ) async {
    final nextState = state.copyWith(
      activeTab: event.tabCategory,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  void _onPeriodChanged(
    AdminPaymentPeriodChanged event,
    Emitter<AdminPaymentState> emit,
  ) {
    emit(state.copyWith(selectedPeriod: event.period));
  }

  Future<void> _onSearchChanged(
    AdminPaymentSearchChanged event,
    Emitter<AdminPaymentState> emit,
  ) async {
    final nextState = state.copyWith(
      searchQuery: event.searchQuery,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onFiltersUpdated(
    AdminPaymentFiltersUpdated event,
    Emitter<AdminPaymentState> emit,
  ) async {
    final nextState = state.copyWith(
      methodFilter: event.methodFilter ?? state.methodFilter,
      statusFilter: event.statusFilter ?? state.statusFilter,
      jenisBankFilter: event.jenisBankFilter ?? state.jenisBankFilter,
      startDate: event.startDate,
      endDate: event.endDate,
      clearDates: event.clearDates,
      minAmount: event.minAmount,
      maxAmount: event.maxAmount,
      clearAmounts: event.clearAmounts,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onFiltersReset(
    AdminPaymentFiltersReset event,
    Emitter<AdminPaymentState> emit,
  ) async {
    final nextState = state.copyWith(
      activeTab: 'ALL',
      searchQuery: '',
      methodFilter: 'ALL',
      statusFilter: 'ALL',
      jenisBankFilter: 'ALL',
      clearDates: true,
      clearAmounts: true,
      sortColumn: 'created_at',
      sortAscending: false,
      currentPage: 1,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onSortChanged(
    AdminPaymentSortChanged event,
    Emitter<AdminPaymentState> emit,
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
    AdminPaymentPageChanged event,
    Emitter<AdminPaymentState> emit,
  ) async {
    final nextState = state.copyWith(
      currentPage: event.page,
      isTableLoading: true,
    );
    emit(nextState);
    await _reloadTable(nextState, emit);
  }

  Future<void> _onDetailRequested(
    AdminPaymentDetailRequested event,
    Emitter<AdminPaymentState> emit,
  ) async {
    emit(state.copyWith(isDetailLoading: true, clearNotifications: true));
    try {
      final detail = await _getAdminPaymentDetailUseCase(event.paymentId);
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
              'Gagal memuat detail pembayaran: ${e.toString().replaceAll('Exception: ', '')}',
        ),
      );
    }
  }

  void _onDetailDismissed(
    AdminPaymentDetailDismissed event,
    Emitter<AdminPaymentState> emit,
  ) {
    emit(state.copyWith(clearSelectedDetail: true));
  }

  Future<void> _onReconcileRequested(
    AdminPaymentReconcileRequested event,
    Emitter<AdminPaymentState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearNotifications: true));
    try {
      final msg = await _reconcilePaymentStatusUseCase(
        paymentId: event.paymentId,
        shipmentId: event.shipmentId,
        notes: event.notes,
      );

      final result = await _fetchPayments(state);
      var nextState = state.copyWith(
        paymentsResult: result,
        isActionInProgress: false,
        actionSuccessMessage: msg,
      );

      if (state.selectedDetail?.payment.id == event.paymentId) {
        final refreshedDetail =
            await _getAdminPaymentDetailUseCase(event.paymentId);
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

  Future<void> _onConfirmCodRequested(
    AdminPaymentConfirmCodRequested event,
    Emitter<AdminPaymentState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, clearNotifications: true));
    try {
      await _confirmCodPaymentUseCase(
        paymentId: event.paymentId,
        shipmentId: event.shipmentId,
        verifiedAmount: event.verifiedAmount,
        settlementReference: event.settlementReference,
        notes: event.notes,
      );

      final result = await _fetchPayments(state);
      var nextState = state.copyWith(
        paymentsResult: result,
        isActionInProgress: false,
        actionSuccessMessage:
            'Pembayaran COD berhasil diverifikasi LUNAS (PAID) dan dicatat pada audit sistem.',
      );

      if (state.selectedDetail?.payment.id == event.paymentId) {
        final refreshedDetail =
            await _getAdminPaymentDetailUseCase(event.paymentId);
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

  void _onClearNotification(
    AdminPaymentClearNotification event,
    Emitter<AdminPaymentState> emit,
  ) {
    emit(state.copyWith(clearNotifications: true));
  }

  Future<void> _reloadTable(
    AdminPaymentState targetState,
    Emitter<AdminPaymentState> emit,
  ) async {
    try {
      final result = await _fetchPayments(targetState);
      emit(
        targetState.copyWith(
          paymentsResult: result,
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

  Future<dynamic> _fetchPayments(AdminPaymentState s) {
    return _getAdminPaymentsUseCase(
      tabCategory: s.activeTab,
      searchQuery: s.searchQuery,
      methodFilter: s.methodFilter,
      statusFilter: s.statusFilter,
      jenisBankFilter: s.jenisBankFilter,
      startDate: s.startDate,
      endDate: s.endDate,
      minAmount: s.minAmount,
      maxAmount: s.maxAmount,
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

