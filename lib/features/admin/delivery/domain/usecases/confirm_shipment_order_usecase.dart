import '../repositories/admin_delivery_repository.dart';

class ConfirmShipmentOrderUseCase {
  final AdminDeliveryRepository repository;

  const ConfirmShipmentOrderUseCase(this.repository);

  Future<void> call({
    required int shipmentId,
    String? notes,
  }) {
    return repository.confirmShipmentOrder(
      shipmentId: shipmentId,
      notes: notes,
    );
  }
}

