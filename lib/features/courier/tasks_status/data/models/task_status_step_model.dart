import '../../domain/entities/task_status_step.dart';

/// Model untuk [TaskStatusStep] yang memetakan data dari tabel `t_shipment_tracking`
class TaskStatusStepModel extends TaskStatusStep {
  const TaskStatusStepModel({
    required super.id,
    required super.shipmentId,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    super.employeeId,
    super.barcodeValue,
    super.locationName,
    super.notes,
    super.latitude,
    super.longitude,
    super.eventSource,
    required super.createdAt,
  });

  /// Factory untuk memetakan dari row database `t_shipment_tracking`
  factory TaskStatusStepModel.fromDatabase(Map<String, dynamic> map) {
    final statusMap = (map['m_shipment_statuses'] is Map<String, dynamic>)
        ? map['m_shipment_statuses'] as Map<String, dynamic>
        : null;

    final statusId = (map['status_id'] as num?)?.toInt() ??
        (statusMap?['id'] as num?)?.toInt() ??
        1;

    final statusCode = statusMap?['kode']?.toString() ??
        map['status_code']?.toString() ??
        _statusCodeFromId(statusId);

    final statusName = statusMap?['nama_status']?.toString() ??
        map['status_name']?.toString() ??
        _statusNameFromCode(statusCode);

    DateTime parsedDate;
    if (map['created_at'] != null) {
      parsedDate = DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return TaskStatusStepModel(
      id: map['id']?.toString() ?? '',
      shipmentId: map['shipment_id']?.toString() ?? '',
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      employeeId: map['employee_id']?.toString(),
      barcodeValue: map['barcode_value']?.toString(),
      locationName: map['lokasi_nama']?.toString(),
      notes: map['catatan']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      eventSource: map['event_source']?.toString(),
      createdAt: parsedDate,
    );
  }

  static String _statusCodeFromId(int id) {
    switch (id) {
      case 1:
        return 'PENDING';
      case 2:
        return 'CONFIRMED';
      case 3:
        return 'PICKUP_SCHEDULED';
      case 4:
        return 'PICKED_UP';
      case 5:
        return 'IN_TRANSIT';
      case 6:
        return 'AT_SORTING_CENTER';
      case 7:
        return 'OUT_FOR_DELIVERY';
      case 8:
        return 'DELIVERED';
      case 9:
        return 'FAILED_DELIVERY';
      case 10:
        return 'RETURNED';
      case 11:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  static String _statusNameFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'CONFIRMED':
        return 'Pesanan Dikonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Dijadwalkan Pickup';
      case 'PICKED_UP':
        return 'Telah Dijemput';
      case 'IN_TRANSIT':
        return 'Dalam Perjalanan';
      case 'AT_SORTING_CENTER':
        return 'Tiba di Fasilitas Sortir';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar';
      case 'DELIVERED':
        return 'Paket Diterima';
      case 'FAILED_DELIVERY':
        return 'Pengantaran Gagal';
      case 'RETURNED':
        return 'Dikembalikan';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return code;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipmentId': shipmentId,
      'statusId': statusId,
      'statusCode': statusCode,
      'statusName': statusName,
      'employeeId': employeeId,
      'barcodeValue': barcodeValue,
      'locationName': locationName,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'eventSource': eventSource,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
