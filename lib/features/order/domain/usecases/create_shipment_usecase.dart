import '../repositories/order_repository.dart';

class CreateShipmentUseCase {
  final OrderRepository repository;

  CreateShipmentUseCase(this.repository);

  Future<void> call(Map<String, dynamic> data) {
    return repository.createShipmentOrder(data);
  }
}
