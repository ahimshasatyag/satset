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
    on<LiveTrackOrdersReceived>(_onOrdersReceived);
    on<LiveTrackOrderSelected>(_onOrderSelected);
    on<LiveTrackZoomChanged>(_onZoomChanged);
    on<LiveTrackResetCenter>(_onResetCenter);
    on<LiveTrackRefreshed>(_onRefreshed);

    add(const LiveTrackStarted());
  }

  void _onStarted(
    LiveTrackStarted event,
    Emitter<LiveTrackState> emit,
  ) {
    final direction = event.initialDirection ?? state.selectedDirection;
    emit(state.copyWith(
      selectedDirection: direction,
      isLoading: true,
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
    ));
    _subscribeToStream(event.direction);
  }

  void _onFilterChanged(
    LiveTrackFilterChanged event,
    Emitter<LiveTrackState> emit,
  ) {
    final filtered = _applyFilter(state.allShipments, event.filterStatus);
    emit(state.copyWith(
      selectedFilterStatus: event.filterStatus,
      filteredShipments: filtered,
      selectedIndex: 0,
    ));
  }

  void _onOrdersReceived(
    LiveTrackOrdersReceived event,
    Emitter<LiveTrackState> emit,
  ) {
    final filtered = _applyFilter(event.shipments, state.selectedFilterStatus);
    final clampedIndex = filtered.isEmpty
        ? 0
        : state.selectedIndex.clamp(0, filtered.length - 1);

    emit(state.copyWith(
      allShipments: event.shipments,
      filteredShipments: filtered,
      selectedIndex: clampedIndex,
      isLoading: false,
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

  void _onZoomChanged(
    LiveTrackZoomChanged event,
    Emitter<LiveTrackState> emit,
  ) {
    final clampedZoom = event.zoomScale.clamp(0.8, 1.8);
    emit(state.copyWith(zoomScale: clampedZoom));
  }

  void _onResetCenter(
    LiveTrackResetCenter event,
    Emitter<LiveTrackState> emit,
  ) {
    emit(state.copyWith(zoomScale: 1.0));
  }

  void _onRefreshed(
    LiveTrackRefreshed event,
    Emitter<LiveTrackState> emit,
  ) {
    _subscribeToStream(state.selectedDirection);
  }

  void _subscribeToStream(OrderDirection direction) {
    _streamSubscription?.cancel();
    _streamSubscription =
        getLiveTrackingOrdersStreamUseCase(direction: direction).listen(
      (shipments) {
        add(LiveTrackOrdersReceived(shipments));
      },
      onError: (error) {
        add(const LiveTrackOrdersReceived([]));
      },
    );
  }

  List<LiveTrackShipment> _applyFilter(
    List<LiveTrackShipment> items,
    OrderFilterStatus filter,
  ) {
    if (filter == OrderFilterStatus.all) return items;
    return items.where((s) => s.filterStatus == filter).toList();
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
