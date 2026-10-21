import 'package:equatable/equatable.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/entities/user_profile.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  final String message;

  const DashboardLoading({this.message = 'Memuat data dashboard SatSet...'});

  @override
  List<Object?> get props => [message];
}

class DashboardLoaded extends DashboardState {
  final Shipment? activeShipment;
  final List<Shipment> recentShipments;
  final ShipmentStatusSummary statusSummary;
  final UserProfile userProfile;
  final Shipment? searchResult;
  final bool isSearching;
  final String? searchError;
  final String? activeStatusFilter;
  final List<String> searchHistory;
  final DateTime lastLiveUpdate;

  const DashboardLoaded({
    this.activeShipment,
    required this.recentShipments,
    required this.statusSummary,
    required this.userProfile,
    this.searchResult,
    this.isSearching = false,
    this.searchError,
    this.activeStatusFilter,
    this.searchHistory = const [],
    required this.lastLiveUpdate,
  });

  DashboardLoaded copyWith({
    Shipment? activeShipment,
    bool clearActiveShipment = false,
    List<Shipment>? recentShipments,
    ShipmentStatusSummary? statusSummary,
    UserProfile? userProfile,
    Shipment? searchResult,
    bool clearSearchResult = false,
    bool? isSearching,
    String? searchError,
    bool clearSearchError = false,
    String? activeStatusFilter,
    bool clearStatusFilter = false,
    List<String>? searchHistory,
    DateTime? lastLiveUpdate,
  }) {
    return DashboardLoaded(
      activeShipment:
          clearActiveShipment ? null : (activeShipment ?? this.activeShipment),
      recentShipments: recentShipments ?? this.recentShipments,
      statusSummary: statusSummary ?? this.statusSummary,
      userProfile: userProfile ?? this.userProfile,
      searchResult:
          clearSearchResult ? null : (searchResult ?? this.searchResult),
      isSearching: isSearching ?? this.isSearching,
      searchError:
          clearSearchError ? null : (searchError ?? this.searchError),
      activeStatusFilter:
          clearStatusFilter ? null : (activeStatusFilter ?? this.activeStatusFilter),
      searchHistory: searchHistory ?? this.searchHistory,
      lastLiveUpdate: lastLiveUpdate ?? this.lastLiveUpdate,
    );
  }

  @override
  List<Object?> get props => [
        activeShipment,
        recentShipments,
        statusSummary,
        userProfile,
        searchResult,
        isSearching,
        searchError,
        activeStatusFilter,
        searchHistory,
        lastLiveUpdate,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
