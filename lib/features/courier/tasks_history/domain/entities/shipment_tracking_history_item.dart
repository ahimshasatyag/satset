import 'package:equatable/equatable.dart';

/// Entitas bisnis catatan jejak kronologis pelacakan riwayat dari [t_shipment_tracking]
class ShipmentTrackingHistoryItem extends Equatable {
  final String id;
  final String shipmentId;
  final int statusId;
  final String statusCode;
  final String statusName;
  final String? employeeId;
  final String? barcodeValue;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? eventSource;
  final DateTime createdAt;

  const ShipmentTrackingHistoryItem({
    required this.id,
    required this.shipmentId,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
    this.employeeId,
    this.barcodeValue,
    this.locationName,
    this.latitude,
    this.longitude,
    this.notes,
    this.eventSource,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        statusId,
        statusCode,
        statusName,
        employeeId,
        barcodeValue,
        locationName,
        notes,
        createdAt,
      ];
}
