import '../entities/delivery_proof_summary.dart';
import '../repositories/courier_task_status_repository.dart';

class GetTaskDeliveryProofUseCase {
  final CourierTaskStatusRepository repository;

  const GetTaskDeliveryProofUseCase(this.repository);

  Future<DeliveryProofSummary?> execute(String shipmentId) {
    return repository.getTaskDeliveryProof(shipmentId);
  }

  Future<DeliveryProofSummary?> call(String shipmentId) {
    return execute(shipmentId);
  }
}
