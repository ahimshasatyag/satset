import '../repositories/admin_delivery_repository.dart';

class HandleFailedDeliveryUseCase {
  final AdminDeliveryRepository repository;

  const HandleFailedDeliveryUseCase(this.repository);

  Future<void> call({
    required int shipmentId,
    required String resolutionAction,
    int? reassignCourierId,
    String? notes,
  }) {
    return repository.handleFailedDelivery(
      shipmentId: shipmentId,
      resolutionAction: resolutionAction,
      reassignCourierId: reassignCourierId,
      notes: notes,
    );
  }
}

