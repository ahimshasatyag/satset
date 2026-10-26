import '../entities/courier_location.dart';
import '../repositories/courier_location_tracking_repository.dart';

/// Use case untuk memperoleh koordinat GPS terkini dari perangkat kurir
class GetCurrentCourierLocationUseCase {
  final CourierLocationTrackingRepository repository;

  GetCurrentCourierLocationUseCase(this.repository);

  Future<CourierLocation?> call() {
    return repository.getCurrentLocation();
  }
}
