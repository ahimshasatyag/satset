import 'package:equatable/equatable.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackState extends Equatable {
  final OrderDirection selectedDirection;
  final OrderFilterStatus selectedFilterStatus;
  final List<LiveTrackShipment> allShipments;
  final List<LiveTrackShipment> filteredShipments;
  final int selectedIndex;
  final String searchQuery;
  final double zoomScale;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final String? initialResiFilter;

  const LiveTrackState({
    this.selectedDirection = OrderDirection.outgoing,
    this.selectedFilterStatus = OrderFilterStatus.all,
    this.allShipments = const [],
    this.filteredShipments = const [],
    this.selectedIndex = 0,
    this.searchQuery = '',
    this.zoomScale = 15.0,
    this.isLoading = true,
    this.isRefreshing = false,
    this.errorMessage,
    this.lastUpdated,
    this.initialResiFilter,
  });

  /// Mengembalikan kurir/pengiriman yang sedang aktif dipilih di peta
  LiveTrackShipment? get selectedShipment {
    if (filteredShipments.isEmpty) return null;
    if (selectedIndex >= 0 && selectedIndex < filteredShipments.length) {
      return filteredShipments[selectedIndex];
    }
    return filteredShipments.first;
  }

  /// Jumlah kurir yang GPS-nya aktif dan sedang mengantar paket
  int get activeCourierCount => filteredShipments
      .where((s) => s.isCourierGpsAvailable && s.filterStatus == OrderFilterStatus.inDelivery)
      .length;

  /// Jumlah seluruh paket yang sedang dalam proses pengiriman (menunggu pickup / dalam pengantaran)
  int get totalActiveCount => filteredShipments.where((s) => s.isActive).length;

  /// Apakah kurir yang sedang dipilih memiliki GPS aktif
  bool get isSelectedGpsAvailable => selectedShipment?.isCourierGpsAvailable ?? false;

  /// Indikator apakah posisi kurir terpilih masih terkini
  bool get isSelectedLocationFresh => selectedShipment?.isLocationFresh ?? false;

  LiveTrackState copyWith({
    OrderDirection? selectedDirection,
    OrderFilterStatus? selectedFilterStatus,
    List<LiveTrackShipment>? allShipments,
    List<LiveTrackShipment>? filteredShipments,
    int? selectedIndex,
    String? searchQuery,
    double? zoomScale,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdated,
    String? initialResiFilter,
  }) {
    return LiveTrackState(
      selectedDirection: selectedDirection ?? this.selectedDirection,
      selectedFilterStatus: selectedFilterStatus ?? this.selectedFilterStatus,
      allShipments: allShipments ?? this.allShipments,
      filteredShipments: filteredShipments ?? this.filteredShipments,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      zoomScale: zoomScale ?? this.zoomScale,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      initialResiFilter: initialResiFilter ?? this.initialResiFilter,
    );
  }

  @override
  List<Object?> get props => [
        selectedDirection,
        selectedFilterStatus,
        allShipments,
        filteredShipments,
        selectedIndex,
        searchQuery,
        zoomScale,
        isLoading,
        isRefreshing,
        errorMessage,
        lastUpdated,
        initialResiFilter,
      ];
}
