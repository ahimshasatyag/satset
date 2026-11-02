import '../entities/admin_shipment_detail.dart';
import '../repositories/admin_dashboard_repository.dart';

class GetAdminShipmentDetailUseCase {
  final AdminDashboardRepository repository;

  GetAdminShipmentDetailUseCase(this.repository);

  Future<AdminShipmentDetail> execute(int shipmentId) {
    return repository.getShipmentDetail(shipmentId);
  }
}

