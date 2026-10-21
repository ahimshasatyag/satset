import '../entities/shipment.dart';
import '../repositories/shipment_repository.dart';

class CreateShipmentUseCase {
  final dynamic repository;

  CreateShipmentUseCase(this.repository);

  Future<OrderShipment> call(Map<String, dynamic> data) {
    if (repository is ShipmentRepository) {
      return (repository as ShipmentRepository).createShipmentOrder(data);
    }
    return repository.createShipmentOrder(data);
  }
}
