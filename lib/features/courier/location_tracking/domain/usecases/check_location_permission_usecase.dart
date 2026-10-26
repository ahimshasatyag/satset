import '../repositories/courier_location_tracking_repository.dart';

/// Hasil pengecekan status izin dan ketersediaan layanan GPS
class LocationPermissionStatus {
  final bool isServiceEnabled;
  final bool hasPermission;

  const LocationPermissionStatus({
    required this.isServiceEnabled,
    required this.hasPermission,
  });

  bool get isReady => isServiceEnabled && hasPermission;
}

/// Use case untuk memeriksa dan meminta izin lokasi perangkat
class CheckLocationPermissionUseCase {
  final CourierLocationTrackingRepository repository;

  CheckLocationPermissionUseCase(this.repository);

  Future<LocationPermissionStatus> check() async {
    final serviceEnabled = await repository.isLocationServiceEnabled();
    final hasPermission = await repository.checkLocationPermission();
    return LocationPermissionStatus(
      isServiceEnabled: serviceEnabled,
      hasPermission: hasPermission,
    );
  }

  Future<bool> request() async {
    return repository.requestLocationPermission();
  }

  Future<void> openSettings() async {
    return repository.openLocationSettings();
  }
}
