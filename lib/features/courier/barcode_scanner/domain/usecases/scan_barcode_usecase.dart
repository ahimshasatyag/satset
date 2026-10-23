import '../entities/barcode_scan_result.dart';
import '../repositories/courier_barcode_scanner_repository.dart';

/// Kasus penggunaan untuk memindai dan memvalidasi barcode paket kurir
class ScanBarcodeUseCase {
  final CourierBarcodeScannerRepository _repository;

  ScanBarcodeUseCase(this._repository);

  Future<BarcodeScanResult> execute({
    required String barcodeValue,
    String? courierId,
    bool force = false,
  }) async {
    final cleanBarcode = barcodeValue.trim();
    if (cleanBarcode.isEmpty) {
      return BarcodeScanResult.unregistered(rawBarcode: '');
    }

    final activeCourierId = await _repository.resolveCourierId(overrideId: courierId);

    return await _repository.scanBarcode(
      barcodeValue: cleanBarcode,
      courierId: activeCourierId,
      force: force,
    );
  }
}
