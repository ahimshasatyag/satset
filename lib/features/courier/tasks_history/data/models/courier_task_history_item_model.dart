import '../../domain/entities/courier_task_history_item.dart';

/// Model implementasi untuk [CourierTaskHistoryItem] dengan mapping database Supabase
class CourierTaskHistoryItemModel extends CourierTaskHistoryItem {
  const CourierTaskHistoryItemModel({
    required super.id,
    required super.shipmentId,
    required super.courierId,
    required super.trackingNumber,
    required super.barcodeValue,
    required super.taskType,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    required super.statusDescription,
    required super.assignmentStatus,
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
    required super.serviceTypeId,
    required super.serviceTypeName,
    required super.serviceTypeCode,
    required super.weightGram,
    required super.itemName,
    required super.itemValue,
    required super.totalFee,
    required super.paymentMethod,
    required super.assignedAt,
    super.acceptedAt,
    super.pickedUpAt,
    super.deliveredAt,
    super.cancelledAt,
    super.completedAt,
    super.failureOrReturnReason,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Factory untuk memetakan data dari join Supabase [t_shipment_assignments]
  /// bersama relasi [t_shipments], [m_shipment_statuses], dan [m_service_types]
  factory CourierTaskHistoryItemModel.fromDatabase(
    Map<String, dynamic> map, {
    String? currentCourierId,
  }) {
    // 1. Ekstrak objek pengiriman utama
    final shipmentMap = (map['t_shipments'] is Map<String, dynamic>)
        ? map['t_shipments'] as Map<String, dynamic>
        : map;

    // 2. Ekstrak data master status pengiriman
    final statusMap = (shipmentMap['m_shipment_statuses'] is Map<String, dynamic>)
        ? shipmentMap['m_shipment_statuses'] as Map<String, dynamic>
        : (map['m_shipment_statuses'] is Map<String, dynamic>
            ? map['m_shipment_statuses'] as Map<String, dynamic>
            : null);

    final statusId = (shipmentMap['status_id'] as num?)?.toInt() ??
        (statusMap?['id'] as num?)?.toInt() ??
        (map['status_id'] as num?)?.toInt() ??
        8; // Default DELIVERED untuk riwayat jika tidak terisi

    final statusCode = statusMap?['kode']?.toString() ??
        shipmentMap['status_code']?.toString() ??
        map['status_code']?.toString() ??
        _statusCodeFromId(statusId);

    final statusName = statusMap?['nama_status']?.toString() ??
        shipmentMap['status_name']?.toString() ??
        map['status_name']?.toString() ??
        _statusNameFromCode(statusCode);

    final statusDescription = statusMap?['deskripsi']?.toString() ??
        _statusDescriptionFromCode(statusCode, statusName);

    // 3. Ekstrak data jenis layanan
    final serviceMap = (shipmentMap['m_service_types'] is Map<String, dynamic>)
        ? shipmentMap['m_service_types'] as Map<String, dynamic>
        : (map['m_service_types'] is Map<String, dynamic>
            ? map['m_service_types'] as Map<String, dynamic>
            : null);

    final serviceTypeId = (shipmentMap['service_type_id'] as num?)?.toInt() ??
        (serviceMap?['id'] as num?)?.toInt() ??
        (map['service_type_id'] as num?)?.toInt() ??
        1;

    final serviceTypeName = serviceMap?['nama_layanan']?.toString() ??
        shipmentMap['service_type_name']?.toString() ??
        _serviceNameFromId(serviceTypeId);

    final serviceTypeCode = serviceMap?['kode']?.toString() ??
        shipmentMap['service_type_code']?.toString() ??
        'REG';

    // 4. Resolusi Jenis Tugas (Pickup vs Delivery)
    final assignmentNotes = (map['catatan'] ?? map['notes'])?.toString().toUpperCase() ?? '';
    final rawType = map['assignment_type']?.toString().toUpperCase() ??
        (assignmentNotes.contains('PICKUP') || statusId <= 4 ? 'PICKUP' : 'DELIVERY');
    final taskType = rawType.contains('PICK')
        ? CourierHistoryTaskType.pickup
        : CourierHistoryTaskType.delivery;

    // 5. Resolusi ID & Identitas Penugasan
    final assignmentId = map['id']?.toString() ??
        map['assignment_id']?.toString() ??
        'ASN-${shipmentMap['id'] ?? '0'}';

    final shipmentId = shipmentMap['id']?.toString() ??
        map['shipment_id']?.toString() ??
        '';

    final courierId = map['courier_id']?.toString() ??
        map['employee_id']?.toString() ??
        currentCourierId ??
        '';

    final assignmentStatus = map['status']?.toString().toUpperCase() ??
        (map['completed_at'] != null || statusId >= 8 ? 'COMPLETED' : 'ASSIGNED');

    final resi = shipmentMap['nomor_resi']?.toString().trim() ??
        map['nomor_resi']?.toString().trim() ??
        'SST-UNKNOWN';

    final barcode = shipmentMap['barcode_value']?.toString().trim() ??
        map['barcode_value']?.toString().trim() ??
        resi;

    // 6. Tanggal dan Timestamp Penugasan & Pengiriman
    final assignedAt = map['assigned_at'] != null
        ? DateTime.tryParse(map['assigned_at'].toString()) ?? DateTime.now()
        : (shipmentMap['created_at'] != null
            ? DateTime.tryParse(shipmentMap['created_at'].toString()) ?? DateTime.now()
            : DateTime.now());

    final acceptedAt = map['accepted_at'] != null
        ? DateTime.tryParse(map['accepted_at'].toString())
        : null;

    final pickedUpAt = shipmentMap['picked_up_at'] != null
        ? DateTime.tryParse(shipmentMap['picked_up_at'].toString())
        : null;

    final deliveredAt = shipmentMap['delivered_at'] != null
        ? DateTime.tryParse(shipmentMap['delivered_at'].toString())
        : null;

    final cancelledAt = shipmentMap['cancelled_at'] != null
        ? DateTime.tryParse(shipmentMap['cancelled_at'].toString())
        : null;

    final completedAt = map['completed_at'] != null
        ? DateTime.tryParse(map['completed_at'].toString())
        : (deliveredAt ?? cancelledAt);

    final createdAt = map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
        : (shipmentMap['created_at'] != null
            ? DateTime.tryParse(shipmentMap['created_at'].toString()) ?? DateTime.now()
            : DateTime.now());

    final updatedAt = map['updated_at'] != null
        ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
        : (shipmentMap['updated_at'] != null
            ? DateTime.tryParse(shipmentMap['updated_at'].toString()) ?? createdAt
            : createdAt);

    // 7. Pengirim & Penerima
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

    // 8. Rincian Paket
    final weight = (shipmentMap['total_berat_gram'] as num?)?.toInt() ?? 1000;
    final itemName = shipmentMap['catatan_pengiriman']?.toString() ??
        shipmentMap['total_barang']?.toString() ??
        'Paket SatSet';
    final itemValue = (shipmentMap['nilai_barang'] as num?)?.toDouble() ?? 0.0;
    final totalFee = (shipmentMap['total_biaya'] as num?)?.toDouble() ??
        (shipmentMap['biaya_pengiriman'] as num?)?.toDouble() ??
        0.0;
    final paymentMethod = shipmentMap['metode_pembayaran']?.toString() ?? 'TRANSFER';

    // 9. Alasan Kegagalan / Pengembalian
    String? failureReason;
    final cleanCode = statusCode.toUpperCase();
    if (cleanCode == 'FAILED_DELIVERY' ||
        cleanCode == 'RETURNED' ||
        cleanCode == 'CANCELLED') {
      failureReason = map['catatan']?.toString() ??
          map['notes']?.toString() ??
          shipmentMap['catatan_pengiriman']?.toString();
    }

    final notes = map['catatan']?.toString() ??
        map['notes']?.toString() ??
        shipmentMap['catatan_pengiriman']?.toString();

    return CourierTaskHistoryItemModel(
      id: assignmentId,
      shipmentId: shipmentId,
      courierId: courierId,
      trackingNumber: resi,
      barcodeValue: barcode,
      taskType: taskType,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      statusDescription: statusDescription,
      assignmentStatus: assignmentStatus,
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
      serviceTypeId: serviceTypeId,
      serviceTypeName: serviceTypeName,
      serviceTypeCode: serviceTypeCode,
      weightGram: weight,
      itemName: itemName,
      itemValue: itemValue,
      totalFee: totalFee,
      paymentMethod: paymentMethod,
      assignedAt: assignedAt,
      acceptedAt: acceptedAt,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      cancelledAt: cancelledAt,
      completedAt: completedAt,
      failureOrReturnReason: failureReason,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CourierTaskHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return CourierTaskHistoryItemModel(
      id: json['id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      courierId: json['courier_id']?.toString() ?? '',
      trackingNumber: json['tracking_number']?.toString() ?? '',
      barcodeValue: json['barcode_value']?.toString() ?? '',
      taskType: json['task_type'] == 'pickup'
          ? CourierHistoryTaskType.pickup
          : CourierHistoryTaskType.delivery,
      statusId: (json['status_id'] as num?)?.toInt() ?? 8,
      statusCode: json['status_code']?.toString() ?? 'DELIVERED',
      statusName: json['status_name']?.toString() ?? 'Paket Diterima',
      statusDescription: json['status_description']?.toString() ?? '',
      assignmentStatus: json['assignment_status']?.toString() ?? 'COMPLETED',
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
      serviceTypeId: (json['service_type_id'] as num?)?.toInt() ?? 1,
      serviceTypeName: json['service_type_name']?.toString() ?? 'Reguler',
      serviceTypeCode: json['service_type_code']?.toString() ?? 'REG',
      weightGram: (json['weight_gram'] as num?)?.toInt() ?? 1000,
      itemName: json['item_name']?.toString() ?? '',
      itemValue: (json['item_value'] as num?)?.toDouble() ?? 0.0,
      totalFee: (json['total_fee'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'TRANSFER',
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'].toString())
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      failureOrReturnReason: json['failure_or_return_reason']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'courier_id': courierId,
      'tracking_number': trackingNumber,
      'barcode_value': barcodeValue,
      'task_type': taskType == CourierHistoryTaskType.pickup ? 'pickup' : 'delivery',
      'status_id': statusId,
      'status_code': statusCode,
      'status_name': statusName,
      'status_description': statusDescription,
      'assignment_status': assignmentStatus,
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
      'service_type_id': serviceTypeId,
      'service_type_name': serviceTypeName,
      'service_type_code': serviceTypeCode,
      'weight_gram': weightGram,
      'item_name': itemName,
      'item_value': itemValue,
      'total_fee': totalFee,
      'payment_method': paymentMethod,
      'assigned_at': assignedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failure_or_return_reason': failureOrReturnReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // --- Resolusi Pembantu ---
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

  static String _statusDescriptionFromCode(String code, String name) {
    switch (code.toUpperCase()) {
      case 'DELIVERED':
        return 'Paket telah berhasil diserahkan kepada penerima di alamat tujuan.';
      case 'FAILED_DELIVERY':
        return 'Pengantaran tidak berhasil diselesaikan karena kendala di lokasi.';
      case 'RETURNED':
        return 'Paket dikembalikan ke pengirim sesuai instruksi sistem.';
      case 'CANCELLED':
        return 'Pengiriman telah dibatalkan oleh pengguna atau sistem.';
      default:
        return 'Status penugasan riwayat $name.';
    }
  }

  static String _serviceNameFromId(int id) {
    switch (id) {
      case 1:
        return 'Reguler';
      case 2:
        return 'Express';
      case 3:
        return 'Same Day';
      default:
        return 'Reguler';
    }
  }
}
