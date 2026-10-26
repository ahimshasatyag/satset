import '../../domain/entities/shipment_tracking_history_item.dart';

/// Model untuk [ShipmentTrackingHistoryItem] dengan mapping data [t_shipment_tracking]
class ShipmentTrackingHistoryItemModel extends ShipmentTrackingHistoryItem {
  const ShipmentTrackingHistoryItemModel({
    required super.id,
    required super.shipmentId,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    super.employeeId,
    super.barcodeValue,
    super.locationName,
    super.latitude,
    super.longitude,
    super.notes,
    super.eventSource,
    required super.createdAt,
  });

  factory ShipmentTrackingHistoryItemModel.fromDatabase(
    Map<String, dynamic> map,
  ) {
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

    return ShipmentTrackingHistoryItemModel(
      id: map['id']?.toString() ?? '',
      shipmentId: map['shipment_id']?.toString() ?? '',
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      employeeId: map['employee_id']?.toString(),
      barcodeValue: map['barcode_value']?.toString(),
      locationName: map['lokasi_nama']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      notes: map['catatan']?.toString(),
      eventSource: map['event_source']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory ShipmentTrackingHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return ShipmentTrackingHistoryItemModel(
      id: json['id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      statusId: (json['status_id'] as num?)?.toInt() ?? 1,
      statusCode: json['status_code']?.toString() ?? 'PENDING',
      statusName: json['status_name']?.toString() ?? 'Menunggu Konfirmasi',
      employeeId: json['employee_id']?.toString(),
      barcodeValue: json['barcode_value']?.toString(),
      locationName: json['lokasi_nama']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['catatan']?.toString(),
      eventSource: json['event_source']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'status_id': statusId,
      'status_code': statusCode,
      'status_name': statusName,
      'employee_id': employeeId,
      'barcode_value': barcodeValue,
      'lokasi_nama': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'catatan': notes,
      'event_source': eventSource,
      'created_at': createdAt.toIso8601String(),
    };
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
        return 'DELIVERED';
    }
  }

  static String _statusNameFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'CONFIRMED':
        return 'Pengiriman Dikonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Menunggu Penjemputan';
      case 'PICKED_UP':
        return 'Paket Dijemput';
      case 'IN_TRANSIT':
        return 'Dalam Perjalanan';
      case 'AT_SORTING_CENTER':
        return 'Tiba di Gudang Sortir';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar';
      case 'DELIVERED':
        return 'Paket Diterima';
      case 'FAILED_DELIVERY':
        return 'Pengantaran Gagal';
      case 'RETURNED':
        return 'Paket Dikembalikan';
      case 'CANCELLED':
        return 'Pengiriman Dibatalkan';
      default:
        return 'Terkirim';
    }
  }
}
