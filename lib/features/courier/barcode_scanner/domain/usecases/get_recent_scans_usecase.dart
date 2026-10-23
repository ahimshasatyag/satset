import '../repositories/courier_barcode_scanner_repository.dart';

/// Kasus penggunaan untuk membaca riwayat pemindaian barcode kurir
class GetRecentScansUseCase {
  final CourierBarcodeScannerRepository _repository;

  GetRecentScansUseCase(this._repository);

  List<String> execute() {
    return _repository.getRecentScannedCodes();
  }

  void clear() {
    _repository.clearScanHistory();
  }
}
