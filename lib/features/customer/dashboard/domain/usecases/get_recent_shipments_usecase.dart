import '../entities/shipment.dart';
import '../repositories/dashboard_repository.dart';

/// Use case untuk memuat daftar riwayat pengiriman pelanggan dari t_shipments
class GetRecentShipmentsUseCase {
  final DashboardRepository repository;

  GetRecentShipmentsUseCase(this.repository);

  Future<List<Shipment>> call({
    int? customerId,
    int limit = 10,
    String? statusFilter,
  }) {
    return repository.getRecentShipments(
      customerId: customerId,
      limit: limit,
      statusFilter: statusFilter,
    );
  }
}
