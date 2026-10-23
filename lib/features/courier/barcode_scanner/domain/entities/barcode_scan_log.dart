import 'package:equatable/equatable.dart';

/// Entitas catatan audit pemindaian barcode pada tabel [t_barcode_scans]
class BarcodeScanLog extends Equatable {
  final String? id;
  final String shipmentId;
  final String courierId;
  final String barcodeValue;
  final String scanType;
  final String status;
  final String? actionType;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final DateTime scannedAt;

  const BarcodeScanLog({
    this.id,
    required this.shipmentId,
    required this.courierId,
    required this.barcodeValue,
    required this.scanType,
    required this.status,
    this.actionType,
    this.location,
    this.latitude,
    this.longitude,
    this.notes,
    required this.scannedAt,
  });

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        courierId,
        barcodeValue,
        scanType,
        status,
        actionType,
        scannedAt,
      ];
}
