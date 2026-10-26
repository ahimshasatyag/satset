import 'package:geolocator/geolocator.dart';
import '../../domain/entities/courier_location.dart';
import '../../domain/entities/courier_tracking_task.dart';
import '../../domain/repositories/courier_location_tracking_repository.dart';
import '../datasources/courier_location_device_datasource.dart';
import '../datasources/courier_location_local_datasource.dart';
import '../datasources/courier_location_remote_datasource.dart';
import '../models/courier_location_model.dart';

class CourierLocationTrackingRepositoryImpl
    implements CourierLocationTrackingRepository {
  final CourierLocationDeviceDataSource deviceDataSource;
  final CourierLocationRemoteDataSource remoteDataSource;
  final CourierLocationLocalDataSource localDataSource;

  CourierLocationTrackingRepositoryImpl({
    required this.deviceDataSource,
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<CourierTrackingTask>> getActiveCourierTasks({
    String? courierId,
  }) async {
    return remoteDataSource.getActiveCourierTasks(courierId: courierId);
  }

  @override
  Future<CourierLocation?> getCurrentLocation() async {
    try {
      final loc = await deviceDataSource.getCurrentPosition();
      await localDataSource.saveLastKnownLocation(loc);
      return loc;
    } catch (_) {
      // Fallback ke cache lokasi terakhir jika GPS perangkat lambat merespons
      return localDataSource.getLastKnownLocation();
    }
  }

  @override
  Stream<CourierLocation> getLiveLocationStream({int distanceFilter = 10}) {
    return deviceDataSource
        .getPositionStream(distanceFilter: distanceFilter)
        .map((loc) {
      localDataSource.saveLastKnownLocation(loc);
      return loc;
    });
  }

  @override
  Future<bool> checkLocationPermission() async {
    try {
      final perm = await deviceDataSource.checkPermission();
      return perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      var perm = await deviceDataSource.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await deviceDataSource.requestPermission();
      }
      return perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await deviceDataSource.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openLocationSettings() async {
    final opened = await deviceDataSource.openLocationSettings();
    if (!opened) {
      await deviceDataSource.openAppSettings();
    }
  }

  @override
  Future<void> sendLocationUpdate({
    required String shipmentId,
    required String courierId,
    required CourierLocation location,
  }) async {
    final model = location is CourierLocationModel
        ? location
        : CourierLocationModel(
            latitude: location.latitude,
            longitude: location.longitude,
            accuracy: location.accuracy,
            altitude: location.altitude,
            speed: location.speed,
            heading: location.heading,
            timestamp: location.timestamp,
          );

    await remoteDataSource.sendLocationUpdate(
      shipmentId: shipmentId,
      courierId: courierId,
      location: model,
    );

    await localDataSource.saveLastKnownLocation(model);
  }

  @override
  Future<CourierLocation?> getLatestSavedLocation({
    required String shipmentId,
  }) async {
    return remoteDataSource.getLatestSavedLocation(shipmentId: shipmentId);
  }

  @override
  Future<bool> isTrackingEnabled() async {
    return localDataSource.isTrackingEnabled();
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    await localDataSource.setTrackingEnabled(enabled);
  }
}
