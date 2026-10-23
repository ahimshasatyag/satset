import '../../domain/entities/barcode_scan_log.dart';
import '../../domain/entities/barcode_scan_result.dart';
import '../../domain/entities/scanned_shipment.dart';
import '../../domain/repositories/courier_barcode_scanner_repository.dart';
import '../datasources/courier_barcode_scanner_local_datasource.dart';
import '../datasources/courier_barcode_scanner_remote_datasource.dart';
import '../models/barcode_scan_log_model.dart';

class CourierBarcodeScannerRepositoryImpl implements CourierBarcodeScannerRepository {
  final CourierBarcodeScannerRemoteDataSource _remoteDataSource;
  final CourierBarcodeScannerLocalDataSource _localDataSource;

  CourierBarcodeScannerRepositoryImpl({
    required CourierBarcodeScannerRemoteDataSource remoteDataSource,
    required CourierBarcodeScannerLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<BarcodeScanResult> scanBarcode({
    required String barcodeValue,
    required String courierId,
    bool force = false,
  }) async {
    final cleanBarcode = barcodeValue.trim();
    if (cleanBarcode.isEmpty) {
      return BarcodeScanResult.unregistered(rawBarcode: '');
    }

    // 1. Cek pencegahan pemindaian duplikat pada sesi yang sama
    if (!force && _localDataSource.isAlreadyScanned(cleanBarcode)) {
      final cachedShipment = await _remoteDataSource.findShipmentByBarcode(
        cleanBarcode,
        activeCourierId: courierId,
      );
      return BarcodeScanResult.duplicate(
        rawBarcode: cleanBarcode,
        shipment: cachedShipment,
      );
    }

    try {
      // 2. Query data pengiriman dari basis data Supabase
      final shipment = await _remoteDataSource.findShipmentByBarcode(
        cleanBarcode,
        activeCourierId: courierId,
      );

      // 3. Validasi keberadaan paket
      if (shipment == null) {
        return BarcodeScanResult.unregistered(rawBarcode: cleanBarcode);
      }

      // 4. Validasi penugasan kurir (RLS & kewenangan tugas)
      if (!shipment.isAssignedToActiveCourier) {
        return BarcodeScanResult.notAssigned(
          rawBarcode: cleanBarcode,
          shipment: shipment,
        );
      }

      // 5. Validasi status alur pengiriman
      if (!shipment.isStatusPermittedForAction) {
        return BarcodeScanResult.invalidStatus(
          rawBarcode: cleanBarcode,
          shipment: shipment,
        );
      }

      // 6. Simpan ke riwayat sesi dan kembalikan hasil sukses
      _localDataSource.addScannedBarcode(cleanBarcode);
      return BarcodeScanResult.success(
        rawBarcode: cleanBarcode,
        shipment: shipment,
      );
    } catch (e) {
      return BarcodeScanResult.serverError(
        rawBarcode: cleanBarcode,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<BarcodeScanResult> processShipmentAction({
    required String shipmentId,
    required String? assignmentId,
    required String newStatusCode,
    required String courierId,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updatedShipment = await _remoteDataSource.updateShipmentStatusAndLog(
        shipmentId: shipmentId,
        assignmentId: assignmentId,
        newStatusCode: newStatusCode,
        courierId: courierId,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
      );

      // Tandai nomor resi/barcode ke dalam riwayat pemindaian sesi
      _localDataSource.addScannedBarcode(updatedShipment.barcodeValue);
      _localDataSource.addScannedBarcode(updatedShipment.trackingNumber);

      return BarcodeScanResult.success(
        rawBarcode: updatedShipment.barcodeValue,
        shipment: updatedShipment,
        message: 'Status paket berhasil diperbarui menjadi ${updatedShipment.statusName}.',
      );
    } catch (e) {
      return BarcodeScanResult.serverError(
        rawBarcode: shipmentId,
        errorMessage: 'Gagal memperbarui status paket: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> recordScanAudit(BarcodeScanLog scanLog) async {
    await _remoteDataSource.recordScanAudit(BarcodeScanLogModel.fromEntity(scanLog));
  }

  @override
  List<String> getRecentScannedCodes() {
    return _localDataSource.getRecentScannedBarcodes();
  }

  @override
  void clearScanHistory() {
    _localDataSource.clearScannedHistory();
  }

  @override
  Stream<ScannedShipment?> streamShipmentUpdates(String shipmentId) {
    return _remoteDataSource.streamShipment(
      shipmentId,
      activeCourierId: '',
    );
  }

  @override
  Future<String> resolveCourierId({String? overrideId}) {
    return _remoteDataSource.resolveCourierId(overrideId: overrideId);
  }
}
