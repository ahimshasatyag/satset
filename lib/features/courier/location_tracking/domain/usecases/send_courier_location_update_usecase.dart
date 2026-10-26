import '../entities/courier_location.dart';
import '../repositories/courier_location_tracking_repository.dart';

/// Use case untuk memvalidasi dan mengirimkan posisi koordinat GPS kurir ke backend
class SendCourierLocationUpdateUseCase {
  final CourierLocationTrackingRepository repository;

  SendCourierLocationUpdateUseCase(this.repository);

  Future<void> call({
    required String shipmentId,
    required String courierId,
    required CourierLocation location,
  }) async {
    // Validasi koordinat sebelum dikirim ke database
    if (!location.isValid) {
      throw Exception('Koordinat GPS tidak valid.');
    }

    if (shipmentId.trim().isEmpty || courierId.trim().isEmpty) {
      throw Exception('ID pengiriman atau kurir tidak boleh kosong.');
    }

    await repository.sendLocationUpdate(
      shipmentId: shipmentId.trim(),
      courierId: courierId.trim(),
      location: location,
    );
  }
}
