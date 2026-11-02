import 'package:equatable/equatable.dart';

/// Entity aktivitas operasional terbaru dari t_shipment_tracking
class AdminActivity extends Equatable {
  final int id;
  final int shipmentId;
  final String nomorResi;
  final String statusCode;
  final String statusName;
  final String lokasiNama;
  final String catatan;
  final String? employeeName;
  final DateTime timestamp;

  const AdminActivity({
    required this.id,
    required this.shipmentId,
    required this.nomorResi,
    required this.statusCode,
    required this.statusName,
    required this.lokasiNama,
    required this.catatan,
    this.employeeName,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        nomorResi,
        statusCode,
        statusName,
        lokasiNama,
        catatan,
        employeeName,
        timestamp,
      ];
}

