import '../entities/delivery_proof_task.dart';
import '../repositories/courier_delivery_proof_repository.dart';

class GetActiveDeliveryTasksUseCase {
  final CourierDeliveryProofRepository repository;

  const GetActiveDeliveryTasksUseCase(this.repository);

  Future<List<DeliveryProofTask>> execute({String? courierId}) {
    return repository.getActiveDeliveryTasks(courierId: courierId);
  }
}
