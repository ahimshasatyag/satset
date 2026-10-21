import '../entities/live_track_shipment.dart';
import '../repositories/live_track_repository.dart';

class GetLiveTrackingOrdersStreamUseCase {
  final LiveTrackRepository repository;

  GetLiveTrackingOrdersStreamUseCase(this.repository);

  Stream<List<LiveTrackShipment>> call({
    required OrderDirection direction,
    String? specificResi,
  }) {
    return repository.getLiveTrackingOrdersStream(
      direction: direction,
      specificResi: specificResi,
    );
  }
}
