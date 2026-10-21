import '../entities/live_track_shipment.dart';
import '../repositories/live_track_repository.dart';

class GetActiveTrackingOrdersUseCase {
  final LiveTrackRepository repository;

  GetActiveTrackingOrdersUseCase(this.repository);

  Future<List<LiveTrackShipment>> call({
    required OrderDirection direction,
    String? specificResi,
  }) {
    return repository.getActiveTrackingOrders(
      direction: direction,
      specificResi: specificResi,
    );
  }
}
