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

  const DashboardLoading({this.message = 'Menghubungkan ke layanan SatSet...'});

  @override
  List<Object?> get props => [message];
}

class DashboardLoaded extends DashboardState {
  final Shipment activeShipment;
  final List<Shipment> recentShipments;
  final UserProfile userProfile;
  final Shipment? searchResult;
  final bool isSearching;
  final String? searchError;
  final DateTime lastLiveUpdate;

  const DashboardLoaded({
    required this.activeShipment,
    required this.recentShipments,
    required this.userProfile,
    this.searchResult,
    this.isSearching = false,
    this.searchError,
    required this.lastLiveUpdate,
  });

  DashboardLoaded copyWith({
    Shipment? activeShipment,
    List<Shipment>? recentShipments,
    UserProfile? userProfile,
    Shipment? searchResult,
    bool clearSearchResult = false,
    bool? isSearching,
    String? searchError,
    bool clearSearchError = false,
    DateTime? lastLiveUpdate,
  }) {
    return DashboardLoaded(
      activeShipment: activeShipment ?? this.activeShipment,
      recentShipments: recentShipments ?? this.recentShipments,
      userProfile: userProfile ?? this.userProfile,
      searchResult:
          clearSearchResult ? null : (searchResult ?? this.searchResult),
      isSearching: isSearching ?? this.isSearching,
      searchError:
          clearSearchError ? null : (searchError ?? this.searchError),
      lastLiveUpdate: lastLiveUpdate ?? this.lastLiveUpdate,
    );
  }

  @override
  List<Object?> get props => [
        activeShipment,
        recentShipments,
        userProfile,
        searchResult,
        isSearching,
        searchError,
        lastLiveUpdate,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
