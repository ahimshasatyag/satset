import '../entities/admin_delivery_detail.dart';
import '../repositories/admin_delivery_repository.dart';

class GetAdminDeliveryDetailUseCase {
  final AdminDeliveryRepository repository;

  const GetAdminDeliveryDetailUseCase(this.repository);

  Future<AdminDeliveryDetail> call(int shipmentId) {
    return repository.getDeliveryDetail(shipmentId);
  }
}

