import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk memuat pengiriman aktif pelanggan yang sedang berjalan
class GetActiveShipmentUseCase {
  final DashboardRepository repository;

  GetActiveShipmentUseCase(this.repository);

  Future<Shipment?> call({int? customerId}) {
    return repository.getActiveShipment(customerId: customerId);
  }
}
