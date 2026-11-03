import '../repositories/admin_delivery_repository.dart';

class UpdateAdminShipmentStatusUseCase {
  final AdminDeliveryRepository repository;

  const UpdateAdminShipmentStatusUseCase(this.repository);

  Future<void> call({
    required int shipmentId,
    required String targetStatusCode,
    String? lokasiNama,
    String? notes,
  }) {
    return repository.updateShipmentStatus(
      shipmentId: shipmentId,
      targetStatusCode: targetStatusCode,
      lokasiNama: lokasiNama,
      notes: notes,
    );
  }
}

