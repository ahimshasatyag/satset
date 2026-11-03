import '../repositories/admin_delivery_repository.dart';

class AssignCourierToShipmentUseCase {
  final AdminDeliveryRepository repository;

  const AssignCourierToShipmentUseCase(this.repository);

  Future<void> call({
    required int shipmentId,
    required int courierId,
    String? notes,
  }) {
    return repository.assignCourierToShipment(
      shipmentId: shipmentId,
      courierId: courierId,
      notes: notes,
    );
  }
}

