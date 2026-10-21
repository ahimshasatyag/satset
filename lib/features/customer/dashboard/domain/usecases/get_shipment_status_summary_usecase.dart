import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk mengambil ringkasan jumlah paket pelanggan berdasarkan 4 kategori status
class GetShipmentStatusSummaryUseCase {
  final DashboardRepository repository;

  GetShipmentStatusSummaryUseCase(this.repository);

  Future<ShipmentStatusSummary> call({int? customerId}) {
    return repository.getShipmentStatusSummary(customerId: customerId);
  }
}
