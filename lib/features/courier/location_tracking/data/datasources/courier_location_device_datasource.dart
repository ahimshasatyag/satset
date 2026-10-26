import 'package:geolocator/geolocator.dart';
import '../models/courier_location_model.dart';

abstract class CourierLocationDeviceDataSource {
  /// Memeriksa apakah GPS / layanan lokasi perangkat aktif
  Future<bool> isLocationServiceEnabled();

  /// Memeriksa status izin lokasi aplikasi
  Future<LocationPermission> checkPermission();

  /// Meminta izin akses lokasi perangkat
  Future<LocationPermission> requestPermission();

  /// Membuka halaman pengaturan lokasi perangkat
  Future<bool> openLocationSettings();

  /// Membuka halaman pengaturan aplikasi
  Future<bool> openAppSettings();

  /// Mengambil posisi GPS terkini perangkat secara presisi
  Future<CourierLocationModel> getCurrentPosition();

  /// Mendengarkan stream perubahan posisi koordinat GPS kurir
  Stream<CourierLocationModel> getPositionStream({
    int distanceFilter = 10,
    int intervalSeconds = 10,
  });
}

class CourierLocationDeviceDataSourceImpl
    implements CourierLocationDeviceDataSource {
  @override
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  @override
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  @override
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  @override
  Future<CourierLocationModel> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return CourierLocationModel.fromPosition(position);
  }

  @override
  Stream<CourierLocationModel> getPositionStream({
    int distanceFilter = 10,
    int intervalSeconds = 10,
  }) {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
      timeLimit: Duration(seconds: intervalSeconds + 5),
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((pos) => CourierLocationModel.fromPosition(pos));
  }
}
