import 'package:equatable/equatable.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackState extends Equatable {
  final OrderDirection selectedDirection;
  final OrderFilterStatus selectedFilterStatus;
  final List<LiveTrackShipment> allShipments;
  final List<LiveTrackShipment> filteredShipments;
  final int selectedIndex;
  final double zoomScale;
  final bool isLoading;
  final String? errorMessage;

  const LiveTrackState({
    this.selectedDirection = OrderDirection.outgoing,
    this.selectedFilterStatus = OrderFilterStatus.all,
    this.allShipments = const [],
    this.filteredShipments = const [],
    this.selectedIndex = 0,
    this.zoomScale = 1.0,
    this.isLoading = true,
    this.errorMessage,
  });

  /// Mengembalikan kurir yang sedang aktif dipilih di peta
  LiveTrackShipment? get selectedShipment {
    if (filteredShipments.isEmpty) return null;
    if (selectedIndex >= 0 && selectedIndex < filteredShipments.length) {
      return filteredShipments[selectedIndex];
    }
    return filteredShipments.first;
  }

  /// Jumlah kurir yang sedang aktif dalam pengantaran
  int get activeCourierCount =>
      filteredShipments.where((s) => s.filterStatus == OrderFilterStatus.inDelivery).length;

  LiveTrackState copyWith({
    OrderDirection? selectedDirection,
    OrderFilterStatus? selectedFilterStatus,
    List<LiveTrackShipment>? allShipments,
    List<LiveTrackShipment>? filteredShipments,
    int? selectedIndex,
    double? zoomScale,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LiveTrackState(
      selectedDirection: selectedDirection ?? this.selectedDirection,
      selectedFilterStatus:
          selectedFilterStatus ?? this.selectedFilterStatus,
      allShipments: allShipments ?? this.allShipments,
      filteredShipments: filteredShipments ?? this.filteredShipments,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      zoomScale: zoomScale ?? this.zoomScale,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        selectedDirection,
        selectedFilterStatus,
        allShipments,
        filteredShipments,
        selectedIndex,
        zoomScale,
        isLoading,
        errorMessage,
      ];
}
