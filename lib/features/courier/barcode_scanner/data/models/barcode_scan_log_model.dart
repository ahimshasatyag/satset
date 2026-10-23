import 'package:satset/app/constants/database_constants.dart';
import '../../domain/entities/barcode_scan_log.dart';

/// Model pencatatan log pemindaian barcode pada tabel t_barcode_scans
class BarcodeScanLogModel extends BarcodeScanLog {
  const BarcodeScanLogModel({
    super.id,
    required super.shipmentId,
    required super.courierId,
    required super.barcodeValue,
    required super.scanType,
    required super.status,
    super.actionType,
    super.location,
    super.latitude,
    super.longitude,
    super.notes,
    required super.scannedAt,
  });

  /// Factory dari entity domain
  factory BarcodeScanLogModel.fromEntity(BarcodeScanLog entity) {
    return BarcodeScanLogModel(
      id: entity.id,
      shipmentId: entity.shipmentId,
      courierId: entity.courierId,
      barcodeValue: entity.barcodeValue,
      scanType: entity.scanType,
      status: entity.status,
      actionType: entity.actionType,
      location: entity.location,
      latitude: entity.latitude,
      longitude: entity.longitude,
      notes: entity.notes,
      scannedAt: entity.scannedAt,
    );
  }

  /// Konversi ke Map untuk insert Supabase
  Map<String, dynamic> toDatabaseMap() {
    final map = <String, dynamic>{
      BarcodeScanTableColumns.shipmentId: shipmentId,
      BarcodeScanTableColumns.courierId: int.tryParse(courierId) ?? courierId,
      BarcodeScanTableColumns.barcodeValue: barcodeValue,
      BarcodeScanTableColumns.scanType: scanType,
      BarcodeScanTableColumns.status: status,
      BarcodeScanTableColumns.scannedAt: scannedAt.toIso8601String(),
    };

    if (actionType != null) {
      map[BarcodeScanTableColumns.actionType] = actionType;
    }
    if (location != null) {
      map[BarcodeScanTableColumns.location] = location;
    }
    if (latitude != null) {
      map[BarcodeScanTableColumns.latitude] = latitude;
    }
    if (longitude != null) {
      map[BarcodeScanTableColumns.longitude] = longitude;
    }
    if (notes != null) {
      map[BarcodeScanTableColumns.notes] = notes;
    }

    return map;
  }
}
