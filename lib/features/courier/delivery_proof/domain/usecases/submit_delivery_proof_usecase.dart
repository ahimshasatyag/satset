import '../entities/delivery_proof_item.dart';
import '../entities/delivery_proof_payload.dart';
import '../repositories/courier_delivery_proof_repository.dart';

class SubmitDeliveryProofUseCase {
  final CourierDeliveryProofRepository repository;

  const SubmitDeliveryProofUseCase(this.repository);

  Future<DeliveryProofItem> execute(DeliveryProofPayload payload) async {
    // 1. Validasi integritas foto bukti
    if (!payload.isImageValid) {
      throw ArgumentError(
        'Foto bukti penyerahan wajib dilampirkan dan tidak boleh lebih dari 10 MB.',
      );
    }

    // 2. Validasi nama penerima aktual
    if (!payload.isRecipientNameValid) {
      throw ArgumentError(
        'Nama penerima aktual wajib diisi sebelum bukti pengiriman dapat dikirim.',
      );
    }

    // 3. Serahkan ke repositori untuk eksekusi upload & update status aman
    return await repository.submitDeliveryProof(payload);
  }
}
