import '../entities/admin_assignable_courier.dart';
import '../repositories/admin_delivery_repository.dart';

class GetAssignableCouriersUseCase {
  final AdminDeliveryRepository repository;

  const GetAssignableCouriersUseCase(this.repository);

  Future<List<AdminAssignableCourier>> call() {
    return repository.getAssignableCouriers();
  }
}

