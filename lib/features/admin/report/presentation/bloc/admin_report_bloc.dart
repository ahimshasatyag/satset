import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/admin_report_remote_datasource.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/repositories/admin_report_repository.dart';
import '../../domain/usecases/export_admin_report_usecase.dart';
import '../../domain/usecases/get_admin_report_data_usecase.dart';
import '../../domain/usecases/get_admin_report_detail_usecase.dart';
import '../../domain/usecases/get_admin_report_references_usecase.dart';
import 'admin_report_event.dart';
import 'admin_report_state.dart';

class AdminReportBloc extends Bloc<AdminReportEvent, AdminReportState> {
  final AdminReportRepository repository;
  final AdminReportRemoteDataSource remoteDataSource;
  final GetAdminReportDataUseCase _getReportDataUseCase;
  final GetAdminReportReferencesUseCase _getReferencesUseCase;
  final GetAdminReportDetailUseCase _getDetailUseCase;
  final ExportAdminReportUseCase _exportUseCase;

  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeDebounce;

  AdminReportBloc({
    required this.repository,
    required this.remoteDataSource,
  })  : _getReportDataUseCase = GetAdminReportDataUseCase(repository),
        _getReferencesUseCase = GetAdminReportReferencesUseCase(repository),
        _getDetailUseCase = GetAdminReportDetailUseCase(repository),
        _exportUseCase = const ExportAdminReportUseCase(),
        super(const AdminReportState()) {
    on<AdminReportStarted>(_onStarted);
    on<AdminReportRefreshed>(_onRefreshed);
    on<AdminReportTypeChanged>(_onReportTypeChanged);
    on<AdminReportDateRangeChanged>(_onDateRangeChanged);
    on<AdminReportFilterUpdated>(_onFilterUpdated);
    on<AdminReportSearchChanged>(_onSearchChanged);
    on<AdminReportSortChanged>(_onSortChanged);
    on<AdminReportPageChanged>(_onPageChanged);
    on<AdminReportFiltersReset>(_onFiltersReset);
    on<AdminReportDetailRequested>(_onDetailRequested);
    on<AdminReportDetailDismissed>(_onDetailDismissed);
    on<AdminReportExportRequested>(_onExportRequested);
    on<AdminReportExportDismissed>(_onExportDismissed);
    on<AdminReportClearFeedback>(_onClearFeedback);
  }

  Future<void> _onStarted(
    AdminReportStarted event,
    Emitter<AdminReportState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminReportStatus.loading,
        clearErrorMessage: true,
        clearDateValidationError: true,
      ),
    );

    final isAuthorized = await repository.verifyAdminAccess();
    if (!isAuthorized) {
      emit(
        state.copyWith(
          status: AdminReportStatus.unauthorized,
          errorMessage:
              'Akses Ditolak: Anda harus masuk menggunakan akun Administrator resmi (m_employee.id_users_role = 1).',
        ),
      );
      return;
    }

    try {
      final references = await _getReferencesUseCase();
      final reportData = await _getReportDataUseCase(state.filter);

      _setupRealtimeSubscription();

      emit(
        state.copyWith(
          status: AdminReportStatus.loaded,
          references: references,
          reportData: reportData,
          filter: reportData.appliedFilter,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminReportStatus.error,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
          isRefreshing: false,
        ),
      );
    }
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = remoteDataSource.subscribeToRealtimeUpdates(
      onDataChanged: () {
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(milliseconds: 900), () {
          if (!isClosed) {
            add(const AdminReportRefreshed());
          }
        });
      },
    );
  }

  Future<void> _reloadWithFilter(
    AdminReportFilter nextFilter,
    Emitter<AdminReportState> emit,
  ) async {
    final validationError = nextFilter.validateDateRange();
    if (validationError != null) {
      emit(
        state.copyWith(
          filter: nextFilter,
          dateValidationError: validationError,
          actionErrorMessage: validationError,
          isRefreshing: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        filter: nextFilter,
        isRefreshing: true,
        clearDateValidationError: true,
        clearActionError: true,
      ),
    );

    try {
      final result = await _getReportDataUseCase(nextFilter);
      emit(
        state.copyWith(
          status: AdminReportStatus.loaded,
          reportData: result,
          filter: result.appliedFilter,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          actionErrorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    AdminReportRefreshed event,
    Emitter<AdminReportState> emit,
  ) async {
    await _reloadWithFilter(state.filter, emit);
  }

  Future<void> _onReportTypeChanged(
    AdminReportTypeChanged event,
    Emitter<AdminReportState> emit,
  ) async {
    String defaultSort = 'created_at';
    switch (event.reportType) {
      case AdminReportType.courier:
        defaultSort = 'total_assigned';
        break;
      case AdminReportType.customer:
        defaultSort = 'total_shipments';
        break;
      case AdminReportType.payment:
      case AdminReportType.shipment:
      default:
        defaultSort = 'created_at';
        break;
    }

    final updated = state.filter.copyWith(
      reportType: event.reportType,
      sortColumn: defaultSort,
      sortAscending: false,
      page: 1,
    );
    await _reloadWithFilter(updated, emit);
  }

  Future<void> _onDateRangeChanged(
    AdminReportDateRangeChanged event,
    Emitter<AdminReportState> emit,
  ) async {
    final updated = state.filter.copyWith(
      startDate: event.startDate,
      clearStartDate: event.startDate == null,
      endDate: event.endDate,
      clearEndDate: event.endDate == null,
      page: 1,
    );
    await _reloadWithFilter(updated, emit);
  }

  Future<void> _onFilterUpdated(
    AdminReportFilterUpdated event,
    Emitter<AdminReportState> emit,
  ) async {
    final updated = state.filter.copyWith(
      shipmentStatusCode: event.shipmentStatusCode,
      serviceTypeCode: event.serviceTypeCode,
      paymentMethod: event.paymentMethod,
      paymentStatus: event.paymentStatus,
      courierId: event.courierId,
      clearCourierId: event.clearCourierId,
      page: 1,
    );
    await _reloadWithFilter(updated, emit);
  }

  Future<void> _onSearchChanged(
    AdminReportSearchChanged event,
    Emitter<AdminReportState> emit,
  ) async {
    final updated = state.filter.copyWith(
      searchQuery: event.query,
      page: 1,
    );
    await _reloadWithFilter(updated, emit);
  }

  Future<void> _onSortChanged(
    AdminReportSortChanged event,
    Emitter<AdminReportState> emit,
  ) async {
    final updated = state.filter.copyWith(
      sortColumn: event.sortColumn,
      sortAscending: event.sortAscending,
      page: 1,
    );
    await _reloadWithFilter(updated, emit);
  }

  Future<void> _onPageChanged(
    AdminReportPageChanged event,
    Emitter<AdminReportState> emit,
  ) async {
    final updated = state.filter.copyWith(page: event.page);
    await _reloadWithFilter(updated, emit);
  }

  Future<void> _onFiltersReset(
    AdminReportFiltersReset event,
    Emitter<AdminReportState> emit,
  ) async {
    final resetFilter = AdminReportFilter(
      reportType: state.filter.reportType,
      pageSize: state.filter.pageSize,
    );
    await _reloadWithFilter(resetFilter, emit);
  }

  Future<void> _onDetailRequested(
    AdminReportDetailRequested event,
    Emitter<AdminReportState> emit,
  ) async {
    emit(
      state.copyWith(
        isDetailLoading: true,
        clearSelectedDetail: true,
        clearActionError: true,
      ),
    );

    try {
      final detail = await _getDetailUseCase(
        reportType: event.reportType,
        recordId: event.recordId,
        currentFilter: state.filter,
      );
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
    AdminReportDetailDismissed event,
    Emitter<AdminReportState> emit,
  ) {
    emit(state.copyWith(clearSelectedDetail: true));
  }

  void _onExportRequested(
    AdminReportExportRequested event,
    Emitter<AdminReportState> emit,
  ) {
    if (state.reportData.totalFilteredCount == 0) {
      emit(
        state.copyWith(
          actionErrorMessage:
              'Tidak ada data pada filter saat ini untuk diekspor.',
        ),
      );
      return;
    }

    final output = _exportUseCase.execute(
      reportData: state.reportData,
      format: event.format,
    );
    emit(state.copyWith(activeExportOutput: output));
  }

  void _onExportDismissed(
    AdminReportExportDismissed event,
    Emitter<AdminReportState> emit,
  ) {
    emit(state.copyWith(clearActiveExport: true));
  }

  void _onClearFeedback(
    AdminReportClearFeedback event,
    Emitter<AdminReportState> emit,
  ) {
    emit(
      state.copyWith(
        clearActionSuccess: true,
        clearActionError: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _realtimeDebounce?.cancel();
    _realtimeChannel?.unsubscribe();
    return super.close();
  }
}

