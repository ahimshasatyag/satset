import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk memuat pengiriman aktif saat inisialisasi awal
class GetActiveShipmentUseCase {
  final DashboardRepository repository;

  GetActiveShipmentUseCase(this.repository);

  Future<Shipment> call() {
    return repository.getActiveShipment();
  }
}
