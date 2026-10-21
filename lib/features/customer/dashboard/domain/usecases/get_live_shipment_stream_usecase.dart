import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk menghubungkan Stream real-time status pengiriman aktif pelanggan
class GetLiveShipmentStreamUseCase {
  final DashboardRepository repository;

  GetLiveShipmentStreamUseCase(this.repository);

  Stream<Shipment?> call({int? customerId}) {
    return repository.getLiveActiveShipmentStream(customerId: customerId);
  }
}
