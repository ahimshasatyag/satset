import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/live_track_shipment.dart';
import '../../domain/usecases/get_live_tracking_orders_stream_usecase.dart';
import 'live_track_event.dart';
import 'live_track_state.dart';

class LiveTrackBloc extends Bloc<LiveTrackEvent, LiveTrackState> {
  final GetLiveTrackingOrdersStreamUseCase getLiveTrackingOrdersStreamUseCase;

  StreamSubscription<List<LiveTrackShipment>>? _streamSubscription;

  LiveTrackBloc({
    required this.getLiveTrackingOrdersStreamUseCase,
  }) : super(const LiveTrackState()) {
    on<LiveTrackStarted>(_onStarted);
    on<LiveTrackDirectionChanged>(_onDirectionChanged);
    on<LiveTrackFilterChanged>(_onFilterChanged);
    on<LiveTrackSearchQueryChanged>(_onSearchQueryChanged);
    on<LiveTrackOrdersReceived>(_onOrdersReceived);
    on<LiveTrackOrderSelected>(_onOrderSelected);
    on<LiveTrackOrderSelectedByResi>(_onOrderSelectedByResi);
    on<LiveTrackZoomChanged>(_onZoomChanged);
    on<LiveTrackResetCenter>(_onResetCenter);
    on<LiveTrackRefreshed>(_onRefreshed);
    on<LiveTrackErrorOccurred>(_onErrorOccurred);

    add(const LiveTrackStarted());
  }

  void _onStarted(
    LiveTrackStarted event,
    Emitter<LiveTrackState> emit,
  ) {
    final direction = event.initialDirection ?? state.selectedDirection;
    final initialResi = event.initialResi;

    emit(state.copyWith(
      selectedDirection: direction,
      initialResiFilter: initialResi,
      searchQuery: '',
      isLoading: true,
      clearError: true,
    ));

    _subscribeToStream(direction);
  }

  void _onDirectionChanged(
    LiveTrackDirectionChanged event,
    Emitter<LiveTrackState> emit,
  ) {
    if (event.direction == state.selectedDirection && !state.isLoading) {
      return;
    }
    emit(state.copyWith(
      selectedDirection: event.direction,
      selectedIndex: 0,
      isLoading: true,
      clearError: true,
    ));
    _subscribeToStream(event.direction, specificResi: state.initialResiFilter);
  }

  void _onFilterChanged(
    LiveTrackFilterChanged event,
    Emitter<LiveTrackState> emit,
  ) {
    final filtered = _applyFilterAndSearch(
      state.allShipments,
      event.filterStatus,
      state.searchQuery,
    );
    emit(state.copyWith(
      selectedFilterStatus: event.filterStatus,
      filteredShipments: filtered,
      selectedIndex: 0,
    ));
  }

  void _onSearchQueryChanged(
    LiveTrackSearchQueryChanged event,
    Emitter<LiveTrackState> emit,
  ) {
    final filtered = _applyFilterAndSearch(
      state.allShipments,
      state.selectedFilterStatus,
      event.query,
    );
    emit(state.copyWith(
      searchQuery: event.query,
      filteredShipments: filtered,
      selectedIndex: 0,
    ));
  }

  void _onOrdersReceived(
    LiveTrackOrdersReceived event,
    Emitter<LiveTrackState> emit,
  ) {
    final filtered = _applyFilterAndSearch(
      event.shipments,
      state.selectedFilterStatus,
      state.searchQuery,
    );

    int targetIndex = 0;
    if (state.initialResiFilter != null && state.initialResiFilter!.isNotEmpty) {
      final found = filtered.indexWhere(
        (s) => s.trackingNumber.equalsIgnoreCase(state.initialResiFilter!),
      );
      if (found != -1) {
        targetIndex = found;
      }
    } else if (state.selectedIndex >= 0 && state.selectedIndex < filtered.length) {
      targetIndex = state.selectedIndex;
    }

    emit(state.copyWith(
      allShipments: event.shipments,
      filteredShipments: filtered,
      selectedIndex: filtered.isEmpty ? 0 : targetIndex,
      isLoading: false,
      isRefreshing: false,
      lastUpdated: DateTime.now(),
      clearError: true,
    ));
  }

  void _onOrderSelected(
    LiveTrackOrderSelected event,
    Emitter<LiveTrackState> emit,
  ) {
    if (state.filteredShipments.isEmpty) return;
    final clamped = event.selectedIndex.clamp(0, state.filteredShipments.length - 1);
    emit(state.copyWith(selectedIndex: clamped));
  }

  void _onOrderSelectedByResi(
    LiveTrackOrderSelectedByResi event,
    Emitter<LiveTrackState> emit,
  ) {
    final idx = state.filteredShipments.indexWhere(
      (s) => s.trackingNumber.trim().toLowerCase() == event.trackingNumber.trim().toLowerCase(),
    );
    if (idx != -1) {
      emit(state.copyWith(selectedIndex: idx));
    }
  }

  void _onZoomChanged(
    LiveTrackZoomChanged event,
    Emitter<LiveTrackState> emit,
  ) {
    final clampedZoom = event.zoomScale.clamp(4.0, 18.0);
    emit(state.copyWith(zoomScale: clampedZoom));
  }

  void _onResetCenter(
    LiveTrackResetCenter event,
    Emitter<LiveTrackState> emit,
  ) {
    emit(state.copyWith(zoomScale: 15.0));
  }

  void _onRefreshed(
    LiveTrackRefreshed event,
    Emitter<LiveTrackState> emit,
  ) {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    _subscribeToStream(state.selectedDirection, specificResi: state.initialResiFilter);
  }

  void _onErrorOccurred(
    LiveTrackErrorOccurred event,
    Emitter<LiveTrackState> emit,
  ) {
    emit(state.copyWith(
      isLoading: false,
      isRefreshing: false,
      errorMessage: event.message,
    ));
  }

  void _subscribeToStream(OrderDirection direction, {String? specificResi}) {
    _streamSubscription?.cancel();
    _streamSubscription = getLiveTrackingOrdersStreamUseCase(
      direction: direction,
      specificResi: specificResi,
    ).listen(
      (shipments) {
        add(LiveTrackOrdersReceived(shipments));
      },
      onError: (error) {
        add(LiveTrackErrorOccurred(error.toString()));
      },
    );
  }

  List<LiveTrackShipment> _applyFilterAndSearch(
    List<LiveTrackShipment> items,
    OrderFilterStatus filter,
    String query,
  ) {
    var result = items;
    if (filter != OrderFilterStatus.all) {
      result = result.where((s) => s.filterStatus == filter).toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((s) {
        return s.trackingNumber.toLowerCase().contains(q) ||
            s.barcodeValue.toLowerCase().contains(q) ||
            s.receiverName.toLowerCase().contains(q) ||
            s.senderName.toLowerCase().contains(q) ||
            s.receiverAddress.toLowerCase().contains(q) ||
            s.serviceTypeName.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}

extension on String {
  bool equalsIgnoreCase(String other) =>
      trim().toLowerCase() == other.trim().toLowerCase();
}
