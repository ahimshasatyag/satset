import '../entities/delivery_proof_task.dart';
import '../repositories/courier_delivery_proof_repository.dart';

class GetDeliveryTaskByIdUseCase {
  final CourierDeliveryProofRepository repository;

  const GetDeliveryTaskByIdUseCase(this.repository);

  Future<DeliveryProofTask?> execute(String shipmentId, {String? courierId}) {
    return repository.getTaskByShipmentId(shipmentId, courierId: courierId);
  }
}
