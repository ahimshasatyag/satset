import 'dart:typed_data';
import '../repositories/courier_delivery_proof_repository.dart';

class PickDeliveryProofImageUseCase {
  final CourierDeliveryProofRepository repository;

  const PickDeliveryProofImageUseCase(this.repository);

  Future<({Uint8List bytes, String fileName, int sizeBytes})?> execute({
    required bool fromCamera,
  }) {
    return repository.pickProofImage(fromCamera: fromCamera);
  }
}
