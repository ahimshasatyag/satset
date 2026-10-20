import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk melacak nomor resi paket via Smart Tracking Bar
class TrackShipmentUseCase {
  final DashboardRepository repository;

  TrackShipmentUseCase(this.repository);

  Future<Shipment?> call(String trackingNumber) {
    return repository.trackShipment(trackingNumber);
  }
}
