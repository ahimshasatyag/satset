import '../entities/barcode_scan_result.dart';
import '../repositories/courier_barcode_scanner_repository.dart';

/// Kasus penggunaan untuk memproses tindakan perubahan status pada paket yang dipindai
class ProcessScannedShipmentUseCase {
  final CourierBarcodeScannerRepository _repository;

  ProcessScannedShipmentUseCase(this._repository);

  Future<BarcodeScanResult> execute({
    required String shipmentId,
    required String? assignmentId,
    required String newStatusCode,
    String? courierId,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final activeCourierId = await _repository.resolveCourierId(overrideId: courierId);

    return await _repository.processShipmentAction(
      shipmentId: shipmentId,
      assignmentId: assignmentId,
      newStatusCode: newStatusCode,
      courierId: activeCourierId,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
