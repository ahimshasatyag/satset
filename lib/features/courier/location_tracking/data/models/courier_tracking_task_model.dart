import '../../domain/entities/courier_tracking_task.dart';

/// Model implementasi [CourierTrackingTask] dengan pemetaan data [t_shipment_assignments] dan [t_shipments]
class CourierTrackingTaskModel extends CourierTrackingTask {
  const CourierTrackingTaskModel({
    required super.taskId,
    required super.shipmentId,
    required super.courierId,
    required super.trackingNumber,
    required super.barcodeValue,
    required super.isPickup,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    required super.senderName,
    required super.senderPhone,
    required super.senderAddress,
    required super.senderCity,
    super.senderLatitude,
    super.senderLongitude,
    required super.receiverName,
    required super.receiverPhone,
    required super.receiverAddress,
    required super.receiverCity,
    super.receiverLatitude,
    super.receiverLongitude,
    required super.serviceTypeName,
    required super.serviceTypeCode,
    required super.assignedAt,
    super.notes,
  });

  factory CourierTrackingTaskModel.fromDatabase(
    Map<String, dynamic> map, {
    String? currentCourierId,
  }) {
    final shipmentMap = (map['t_shipments'] is Map<String, dynamic>)
        ? map['t_shipments'] as Map<String, dynamic>
        : map;

    final statusMap = (shipmentMap['m_shipment_statuses'] is Map<String, dynamic>)
        ? shipmentMap['m_shipment_statuses'] as Map<String, dynamic>
        : (map['m_shipment_statuses'] is Map<String, dynamic>
            ? map['m_shipment_statuses'] as Map<String, dynamic>
            : null);

    final statusId = (shipmentMap['status_id'] as num?)?.toInt() ??
        (statusMap?['id'] as num?)?.toInt() ??
        (map['status_id'] as num?)?.toInt() ??
        7;

    final statusCode = statusMap?['kode']?.toString() ??
        shipmentMap['status_code']?.toString() ??
        map['status_code']?.toString() ??
        _statusCodeFromId(statusId);

    final statusName = statusMap?['nama_status']?.toString() ??
        shipmentMap['status_name']?.toString() ??
        map['status_name']?.toString() ??
        _statusNameFromCode(statusCode);

    final serviceMap = (shipmentMap['m_service_types'] is Map<String, dynamic>)
        ? shipmentMap['m_service_types'] as Map<String, dynamic>
        : (map['m_service_types'] is Map<String, dynamic>
            ? map['m_service_types'] as Map<String, dynamic>
            : null);

    final serviceTypeName = serviceMap?['nama_layanan']?.toString() ??
        shipmentMap['service_type_name']?.toString() ??
        'Reguler';

    final serviceTypeCode = serviceMap?['kode']?.toString() ??
        shipmentMap['service_type_code']?.toString() ??
        'REG';

    final assignmentNotes = (map['catatan'] ?? map['notes'])?.toString().toUpperCase() ?? '';
    final rawType = map['assignment_type']?.toString().toUpperCase() ??
        (assignmentNotes.contains('PICKUP') || statusId <= 4 ? 'PICKUP' : 'DELIVERY');
    final isPickup = rawType.contains('PICK');

    final taskId = map['id']?.toString() ??
        map['assignment_id']?.toString() ??
        'ASN-${shipmentMap['id'] ?? '0'}';

    final shipmentId = shipmentMap['id']?.toString() ??
        map['shipment_id']?.toString() ??
        '';

    final courierId = map['courier_id']?.toString() ??
        map['employee_id']?.toString() ??
        currentCourierId ??
        '';

    final resi = shipmentMap['nomor_resi']?.toString().trim() ??
        map['nomor_resi']?.toString().trim() ??
        'SST-UNKNOWN';

    final barcode = shipmentMap['barcode_value']?.toString().trim() ??
        map['barcode_value']?.toString().trim() ??
        resi;

    final assignedAt = map['assigned_at'] != null
        ? DateTime.tryParse(map['assigned_at'].toString()) ?? DateTime.now()
        : (shipmentMap['created_at'] != null
            ? DateTime.tryParse(shipmentMap['created_at'].toString()) ?? DateTime.now()
            : DateTime.now());

    final senderName = shipmentMap['pengirim_nama']?.toString() ?? 'Pengirim SatSet';
    final senderPhone = shipmentMap['pengirim_no_hp']?.toString() ?? '-';
    final senderAddress = shipmentMap['pengirim_alamat']?.toString() ?? '-';
    final senderCity = shipmentMap['pengirim_kota']?.toString() ?? 'Indonesia';
    final senderLat = (shipmentMap['pengirim_latitude'] as num?)?.toDouble();
    final senderLng = (shipmentMap['pengirim_longitude'] as num?)?.toDouble();

    final receiverName = shipmentMap['penerima_nama']?.toString() ?? 'Penerima SatSet';
    final receiverPhone = shipmentMap['penerima_no_hp']?.toString() ?? '-';
    final receiverAddress = shipmentMap['penerima_alamat']?.toString() ?? '-';
    final receiverCity = shipmentMap['penerima_kota']?.toString() ?? 'Indonesia';
    final receiverLat = (shipmentMap['penerima_latitude'] as num?)?.toDouble();
    final receiverLng = (shipmentMap['penerima_longitude'] as num?)?.toDouble();

    final notes = map['catatan']?.toString() ??
        map['notes']?.toString() ??
        shipmentMap['catatan_pengiriman']?.toString();

    return CourierTrackingTaskModel(
      taskId: taskId,
      shipmentId: shipmentId,
      courierId: courierId,
      trackingNumber: resi,
      barcodeValue: barcode,
      isPickup: isPickup,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      senderName: senderName,
      senderPhone: senderPhone,
      senderAddress: senderAddress,
      senderCity: senderCity,
      senderLatitude: senderLat,
      senderLongitude: senderLng,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      receiverAddress: receiverAddress,
      receiverCity: receiverCity,
      receiverLatitude: receiverLat,
      receiverLongitude: receiverLng,
      serviceTypeName: serviceTypeName,
      serviceTypeCode: serviceTypeCode,
      assignedAt: assignedAt,
      notes: notes,
    );
  }

  factory CourierTrackingTaskModel.fromJson(Map<String, dynamic> json) {
    return CourierTrackingTaskModel(
      taskId: json['task_id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      courierId: json['courier_id']?.toString() ?? '',
      trackingNumber: json['tracking_number']?.toString() ?? '',
      barcodeValue: json['barcode_value']?.toString() ?? '',
      isPickup: json['is_pickup'] as bool? ?? false,
      statusId: (json['status_id'] as num?)?.toInt() ?? 7,
      statusCode: json['status_code']?.toString() ?? 'OUT_FOR_DELIVERY',
      statusName: json['status_name']?.toString() ?? 'Sedang Diantar',
      senderName: json['sender_name']?.toString() ?? '',
      senderPhone: json['sender_phone']?.toString() ?? '',
      senderAddress: json['sender_address']?.toString() ?? '',
      senderCity: json['sender_city']?.toString() ?? '',
      senderLatitude: (json['sender_latitude'] as num?)?.toDouble(),
      senderLongitude: (json['sender_longitude'] as num?)?.toDouble(),
      receiverName: json['receiver_name']?.toString() ?? '',
      receiverPhone: json['receiver_phone']?.toString() ?? '',
      receiverAddress: json['receiver_address']?.toString() ?? '',
      receiverCity: json['receiver_city']?.toString() ?? '',
      receiverLatitude: (json['receiver_latitude'] as num?)?.toDouble(),
      receiverLongitude: (json['receiver_longitude'] as num?)?.toDouble(),
      serviceTypeName: json['service_type_name']?.toString() ?? 'Reguler',
      serviceTypeCode: json['service_type_code']?.toString() ?? 'REG',
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'shipment_id': shipmentId,
      'courier_id': courierId,
      'tracking_number': trackingNumber,
      'barcode_value': barcodeValue,
      'is_pickup': isPickup,
      'status_id': statusId,
      'status_code': statusCode,
      'status_name': statusName,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'sender_address': senderAddress,
      'sender_city': senderCity,
      'sender_latitude': senderLatitude,
      'sender_longitude': senderLongitude,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'receiver_address': receiverAddress,
      'receiver_city': receiverCity,
      'receiver_latitude': receiverLatitude,
      'receiver_longitude': receiverLongitude,
      'service_type_name': serviceTypeName,
      'service_type_code': serviceTypeCode,
      'assigned_at': assignedAt.toIso8601String(),
      'notes': notes,
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
        return 'OUT_FOR_DELIVERY';
    }
  }

  static String _statusNameFromCode(String code) {
    switch (code.toUpperCase()) {
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
      default:
        return 'Sedang Berjalan';
    }
  }
}
