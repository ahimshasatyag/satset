import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_active_shipment_usecase.dart';
import '../../domain/usecases/get_live_shipment_stream_usecase.dart';
import '../../domain/usecases/get_recent_shipments_usecase.dart';
import '../../domain/usecases/get_shipment_status_summary_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/track_shipment_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetLiveShipmentStreamUseCase getLiveShipmentStreamUseCase;
  final GetActiveShipmentUseCase getActiveShipmentUseCase;
  final GetRecentShipmentsUseCase getRecentShipmentsUseCase;
  final GetShipmentStatusSummaryUseCase getShipmentStatusSummaryUseCase;
  final TrackShipmentUseCase trackShipmentUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final DashboardRepository repository;

  StreamSubscription? _liveShipmentSubscription;
  int? _resolvedCustomerId;

  DashboardBloc({
    required this.getLiveShipmentStreamUseCase,
    required this.getActiveShipmentUseCase,
    required this.getRecentShipmentsUseCase,
    required this.getShipmentStatusSummaryUseCase,
    required this.trackShipmentUseCase,
    required this.getUserProfileUseCase,
    required this.repository,
  }) : super(const DashboardInitial()) {
    on<DashboardInitializeRequested>(_onInitializeRequested);
    on<DashboardLiveShipmentReceived>(_onLiveShipmentReceived);
    on<DashboardTrackNumberSubmitted>(_onTrackNumberSubmitted);
    on<DashboardBarcodeScanned>(_onBarcodeScanned);
    on<DashboardStatusFilterChanged>(_onStatusFilterChanged);
    on<DashboardClearSearchResult>(_onClearSearchResult);
    on<DashboardNotificationTapped>(_onNotificationTapped);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardClearHistoryRequested>(_onClearHistoryRequested);
  }

  Future<void> _onInitializeRequested(
    DashboardInitializeRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading(
      message: 'Memuat data pengiriman pelanggan dari SatSet Supabase...',
    ));
    try {
      final userProfile = await getUserProfileUseCase(userId: event.userId);
      _resolvedCustomerId = event.customerId ?? int.tryParse(userProfile.id);

      final statusSummary = await getShipmentStatusSummaryUseCase(
        customerId: _resolvedCustomerId,
      );
      final activeShipment = await getActiveShipmentUseCase(
        customerId: _resolvedCustomerId,
      );
      final recentShipments = await getRecentShipmentsUseCase(
        customerId: _resolvedCustomerId,
      );
      final searchHistory = await repository.getSearchHistory();

      emit(DashboardLoaded(
        activeShipment: activeShipment,
        recentShipments: recentShipments,
        statusSummary: statusSummary,
        userProfile: userProfile,
        searchHistory: searchHistory,
        lastLiveUpdate: DateTime.now(),
      ));

      // Berlangganan ke Stream Real-Time Supabase
      await _liveShipmentSubscription?.cancel();
      _liveShipmentSubscription = getLiveShipmentStreamUseCase(
        customerId: _resolvedCustomerId,
      ).listen((updatedShipment) {
        add(DashboardLiveShipmentReceived(updatedShipment));
      });
    } catch (e) {
      emit(DashboardError('Gagal memuat dashboard: ${e.toString()}'));
    }
  }

  void _onLiveShipmentReceived(
    DashboardLiveShipmentReceived event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(
        activeShipment: event.shipment,
        clearActiveShipment: event.shipment == null,
        lastLiveUpdate: DateTime.now(),
      ));
    }
  }

  Future<void> _onStatusFilterChanged(
    DashboardStatusFilterChanged event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        final filteredShipments = await getRecentShipmentsUseCase(
          customerId: _resolvedCustomerId,
          statusFilter: event.statusFilter,
        );
        emit(currentState.copyWith(
          recentShipments: filteredShipments,
          activeStatusFilter: event.statusFilter,
          clearStatusFilter: event.statusFilter == null,
        ));
      } catch (_) {}
    }
  }

  Future<void> _onTrackNumberSubmitted(
    DashboardTrackNumberSubmitted event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(currentState.copyWith(isSearching: true, clearSearchError: true));

      try {
        final result = await trackShipmentUseCase(event.trackingNumber);
        final updatedHistory = await repository.getSearchHistory();

        if (result != null) {
          emit(currentState.copyWith(
            searchResult: result,
            isSearching: false,
            searchHistory: updatedHistory,
            clearSearchError: true,
          ));
        } else {
          emit(currentState.copyWith(
            isSearching: false,
            searchHistory: updatedHistory,
            searchError: 'Nomor resi "${event.trackingNumber}" tidak ditemukan.',
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(
          isSearching: false,
          searchError: 'Gagal melacak resi: ${e.toString()}',
        ));
      }
    }
  }

  void _onClearSearchResult(
    DashboardClearSearchResult event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      emit((state as DashboardLoaded).copyWith(clearSearchResult: true));
    }
  }

  Future<void> _onBarcodeScanned(
    DashboardBarcodeScanned event,
    Emitter<DashboardState> emit,
  ) async {
    add(DashboardTrackNumberSubmitted(event.scannedCode));
  }

  Future<void> _onNotificationTapped(
    DashboardNotificationTapped event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      await repository.markNotificationsAsRead();
      emit(currentState.copyWith(
        userProfile: currentState.userProfile.copyWith(
          hasUnreadCourierUpdates: false,
          unreadCount: 0,
        ),
      ));
    }
  }

  Future<void> _onClearHistoryRequested(
    DashboardClearHistoryRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      await repository.clearSearchHistory();
      emit((state as DashboardLoaded).copyWith(searchHistory: const []));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final userProfile = await getUserProfileUseCase();
      _resolvedCustomerId = int.tryParse(userProfile.id);

      final statusSummary = await getShipmentStatusSummaryUseCase(
        customerId: _resolvedCustomerId,
      );
      final activeShipment = await getActiveShipmentUseCase(
        customerId: _resolvedCustomerId,
      );
      final recentShipments = await getRecentShipmentsUseCase(
        customerId: _resolvedCustomerId,
      );
      final searchHistory = await repository.getSearchHistory();

      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        emit(currentState.copyWith(
          activeShipment: activeShipment,
          clearActiveShipment: activeShipment == null,
          recentShipments: recentShipments,
          statusSummary: statusSummary,
          userProfile: userProfile,
          searchHistory: searchHistory,
          lastLiveUpdate: DateTime.now(),
        ));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _liveShipmentSubscription?.cancel();
    return super.close();
  }
}
