import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk memuat daftar riwayat pengiriman terakhir
class GetRecentShipmentsUseCase {
  final DashboardRepository repository;

  GetRecentShipmentsUseCase(this.repository);

  Future<List<Shipment>> call() {
    return repository.getRecentShipments();
  }
}
