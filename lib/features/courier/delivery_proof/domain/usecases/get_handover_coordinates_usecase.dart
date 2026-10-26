import '../repositories/courier_delivery_proof_repository.dart';

class GetHandoverCoordinatesUseCase {
  final CourierDeliveryProofRepository repository;

  const GetHandoverCoordinatesUseCase(this.repository);

  Future<({double latitude, double longitude})?> execute() {
    return repository.getCurrentHandoverCoordinates();
  }
}
