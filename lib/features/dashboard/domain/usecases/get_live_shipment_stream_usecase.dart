import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk menghubungkan Stream real-time status pengiriman aktif
class GetLiveShipmentStreamUseCase {
  final DashboardRepository repository;

  GetLiveShipmentStreamUseCase(this.repository);

  Stream<Shipment> call() {
    return repository.getLiveActiveShipmentStream();
  }
}
