import '../entities/courier_location.dart';
import '../repositories/courier_location_tracking_repository.dart';

/// Use case untuk berlangganan aliran pembaruan koordinat GPS kurir
class StreamCourierLocationUseCase {
  final CourierLocationTrackingRepository repository;

  StreamCourierLocationUseCase(this.repository);

  Stream<CourierLocation> call({int distanceFilter = 10}) {
    return repository.getLiveLocationStream(distanceFilter: distanceFilter);
  }
}
