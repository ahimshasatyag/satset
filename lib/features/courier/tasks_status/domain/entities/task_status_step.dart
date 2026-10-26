import 'package:equatable/equatable.dart';

/// Entity representasi tahapan riwayat perubahan status pengiriman dari `t_shipment_tracking`
class TaskStatusStep extends Equatable {
  final String id;
  final String shipmentId;
  final int statusId;
  final String statusCode;
  final String statusName;
  final String? employeeId;
  final String? barcodeValue;
  final String? locationName;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String? eventSource;
  final DateTime createdAt;

  const TaskStatusStep({
    required this.id,
    required this.shipmentId,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
    this.employeeId,
    this.barcodeValue,
    this.locationName,
    this.notes,
    this.latitude,
    this.longitude,
    this.eventSource,
    required this.createdAt,
  });

  /// True jika tahapan memiliki koordinat GPS tercatat
  bool get hasLocation => latitude != null && longitude != null;

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
        latitude,
        longitude,
        eventSource,
        createdAt,
      ];
}
