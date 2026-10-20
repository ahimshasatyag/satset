import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_active_shipment_usecase.dart';
import '../../domain/usecases/get_live_shipment_stream_usecase.dart';
import '../../domain/usecases/get_recent_shipments_usecase.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/track_shipment_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetLiveShipmentStreamUseCase getLiveShipmentStreamUseCase;
  final GetActiveShipmentUseCase getActiveShipmentUseCase;
  final GetRecentShipmentsUseCase getRecentShipmentsUseCase;
  final TrackShipmentUseCase trackShipmentUseCase;
  final GetUserProfileUseCase getUserProfileUseCase;
  final DashboardRepository repository;

  StreamSubscription? _liveShipmentSubscription;

  DashboardBloc({
    required this.getLiveShipmentStreamUseCase,
    required this.getActiveShipmentUseCase,
    required this.getRecentShipmentsUseCase,
    required this.trackShipmentUseCase,
    required this.getUserProfileUseCase,
    required this.repository,
  }) : super(const DashboardInitial()) {
    on<DashboardInitializeRequested>(_onInitializeRequested);
    on<DashboardLiveShipmentReceived>(_onLiveShipmentReceived);
    on<DashboardTrackNumberSubmitted>(_onTrackNumberSubmitted);
    on<DashboardBarcodeScanned>(_onBarcodeScanned);
    on<DashboardNotificationTapped>(_onNotificationTapped);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onInitializeRequested(
    DashboardInitializeRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading(
        message: 'Menginisialisasi koneksi real-time SatSet...'));
    try {
      final userProfile = await getUserProfileUseCase();
      final activeShipment = await getActiveShipmentUseCase();
      final recentShipments = await getRecentShipmentsUseCase();

      emit(DashboardLoaded(
        activeShipment: activeShipment,
        recentShipments: recentShipments,
        userProfile: userProfile,
        lastLiveUpdate: DateTime.now(),
      ));

      // Berlangganan ke Stream Real-Time (WebSocket/Firestore)
      await _liveShipmentSubscription?.cancel();
      _liveShipmentSubscription =
          getLiveShipmentStreamUseCase().listen((updatedShipment) {
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
        lastLiveUpdate: DateTime.now(),
      ));
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
        if (result != null) {
          emit(currentState.copyWith(
            searchResult: result,
            isSearching: false,
            clearSearchError: true,
          ));
        } else {
          emit(currentState.copyWith(
            isSearching: false,
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

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final activeShipment = await getActiveShipmentUseCase();
      final recentShipments = await getRecentShipmentsUseCase();
      final userProfile = await getUserProfileUseCase();

      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        emit(currentState.copyWith(
          activeShipment: activeShipment,
          recentShipments: recentShipments,
          userProfile: userProfile,
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
