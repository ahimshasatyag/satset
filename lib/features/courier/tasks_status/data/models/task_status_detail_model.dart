import '../../domain/entities/task_status_detail.dart';

/// Model untuk [TaskStatusDetail] yang memetakan data relasi database Supabase
class TaskStatusDetailModel extends TaskStatusDetail {
  const TaskStatusDetailModel({
    required super.shipmentId,
    required super.assignmentId,
    required super.trackingNumber,
    super.barcodeValue,
    required super.senderName,
    required super.senderPhone,
    required super.senderAddress,
    required super.senderCity,
    super.senderPostalCode,
    super.senderLatitude,
    super.senderLongitude,
    required super.receiverName,
    required super.receiverPhone,
    required super.receiverAddress,
    required super.receiverCity,
    super.receiverPostalCode,
    super.receiverLatitude,
    super.receiverLongitude,
    super.serviceTypeName,
    super.serviceTypeCode,
    super.totalWeightGram,
    super.shippingCost,
    super.paymentMethod,
    super.shippingNotes,
    required super.currentStatusId,
    required super.currentStatusCode,
    required super.currentStatusName,
    super.isFinalStatus = false,
    super.assignedAt,
    super.pickedUpAt,
    super.deliveredAt,
    super.estimatedArrival,
    required super.createdAt,
    super.updatedAt,
  });

  /// Factory untuk memetakan dari query Supabase (bisa dari t_shipments join assignment atau sebaliknya)
  factory TaskStatusDetailModel.fromDatabase(Map<String, dynamic> rawMap) {
    // 1. Ekstrak data shipment dan assignment
    Map<String, dynamic> shipmentMap = rawMap;
    Map<String, dynamic>? assignmentMap;

    if (rawMap['t_shipments'] is Map<String, dynamic>) {
      shipmentMap = rawMap['t_shipments'] as Map<String, dynamic>;
      assignmentMap = rawMap;
    } else if (rawMap['t_shipment_assignments'] is List &&
        (rawMap['t_shipment_assignments'] as List).isNotEmpty) {
      assignmentMap = (rawMap['t_shipment_assignments'] as List).first as Map<String, dynamic>;
    } else if (rawMap['t_shipment_assignments'] is Map<String, dynamic>) {
      assignmentMap = rawMap['t_shipment_assignments'] as Map<String, dynamic>;
    }

    // 2. Ekstrak status
    Map<String, dynamic>? statusMap;
    if (shipmentMap['m_shipment_statuses'] is Map<String, dynamic>) {
      statusMap = shipmentMap['m_shipment_statuses'] as Map<String, dynamic>;
    } else if (rawMap['m_shipment_statuses'] is Map<String, dynamic>) {
      statusMap = rawMap['m_shipment_statuses'] as Map<String, dynamic>;
    }

    final int statusId = (shipmentMap['status_id'] as num?)?.toInt() ??
        (statusMap?['id'] as num?)?.toInt() ??
        (rawMap['status_id'] as num?)?.toInt() ??
        1;

    final String statusCode = statusMap?['kode']?.toString() ??
        rawMap['status_code']?.toString() ??
        _statusCodeFromId(statusId);

    final String statusName = statusMap?['nama_status']?.toString() ??
        rawMap['status_name']?.toString() ??
        _statusNameFromCode(statusCode);

    final bool isFinal = (statusMap?['is_final'] as bool?) ??
        (statusCode == 'DELIVERED' || statusCode == 'CANCELLED' || statusCode == 'RETURNED');

    // 3. Ekstrak tipe layanan (m_service_types)
    Map<String, dynamic>? serviceMap;
    if (shipmentMap['m_service_types'] is Map<String, dynamic>) {
      serviceMap = shipmentMap['m_service_types'] as Map<String, dynamic>;
    } else if (rawMap['m_service_types'] is Map<String, dynamic>) {
      serviceMap = rawMap['m_service_types'] as Map<String, dynamic>;
    }

    final serviceTypeName = serviceMap?['nama_layanan']?.toString() ??
        rawMap['service_type_name']?.toString();
    final serviceTypeCode = serviceMap?['kode']?.toString() ??
        rawMap['service_type_code']?.toString();

    // 4. Ekstrak tanggal
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final createdAt = parseDate(shipmentMap['created_at']) ??
        parseDate(rawMap['created_at']) ??
        DateTime.now();
    final updatedAt = parseDate(shipmentMap['updated_at']) ??
        parseDate(rawMap['updated_at']);
    final assignedAt = parseDate(assignmentMap?['assigned_at']) ??
        parseDate(rawMap['assigned_at']);
    final pickedUpAt = parseDate(shipmentMap['picked_up_at']) ??
        parseDate(rawMap['picked_up_at']);
    final deliveredAt = parseDate(shipmentMap['delivered_at']) ??
        parseDate(rawMap['delivered_at']);
    final estimatedArrival = parseDate(shipmentMap['estimasi_tiba']) ??
        parseDate(rawMap['estimasi_tiba']);

    return TaskStatusDetailModel(
      shipmentId: shipmentMap['id']?.toString() ?? rawMap['shipment_id']?.toString() ?? '',
      assignmentId: assignmentMap?['id']?.toString() ?? rawMap['assignment_id']?.toString() ?? '',
      trackingNumber: shipmentMap['nomor_resi']?.toString() ??
          rawMap['nomor_resi']?.toString() ??
          rawMap['tracking_number']?.toString() ??
          '-',
      barcodeValue: shipmentMap['barcode_value']?.toString() ??
          rawMap['barcode_value']?.toString() ??
          shipmentMap['nomor_resi']?.toString(),
      senderName: shipmentMap['pengirim_nama']?.toString() ??
          rawMap['pengirim_nama']?.toString() ??
          'Pengirim',
      senderPhone: shipmentMap['pengirim_no_hp']?.toString() ??
          rawMap['pengirim_no_hp']?.toString() ??
          '-',
      senderAddress: shipmentMap['pengirim_alamat']?.toString() ??
          rawMap['pengirim_alamat']?.toString() ??
          '-',
      senderCity: shipmentMap['pengirim_kota']?.toString() ??
          rawMap['pengirim_kota']?.toString() ??
          '',
      senderPostalCode: shipmentMap['pengirim_kode_pos']?.toString(),
      senderLatitude: (shipmentMap['pengirim_latitude'] as num?)?.toDouble() ??
          (rawMap['sender_latitude'] as num?)?.toDouble(),
      senderLongitude: (shipmentMap['pengirim_longitude'] as num?)?.toDouble() ??
          (rawMap['sender_longitude'] as num?)?.toDouble(),
      receiverName: shipmentMap['penerima_nama']?.toString() ??
          rawMap['penerima_nama']?.toString() ??
          'Penerima',
      receiverPhone: shipmentMap['penerima_no_hp']?.toString() ??
          rawMap['penerima_no_hp']?.toString() ??
          '-',
      receiverAddress: shipmentMap['penerima_alamat']?.toString() ??
          rawMap['penerima_alamat']?.toString() ??
          '-',
      receiverCity: shipmentMap['penerima_kota']?.toString() ??
          rawMap['penerima_kota']?.toString() ??
          '',
      receiverPostalCode: shipmentMap['penerima_kode_pos']?.toString(),
      receiverLatitude: (shipmentMap['penerima_latitude'] as num?)?.toDouble() ??
          (rawMap['receiver_latitude'] as num?)?.toDouble(),
      receiverLongitude: (shipmentMap['penerima_longitude'] as num?)?.toDouble() ??
          (rawMap['receiver_longitude'] as num?)?.toDouble(),
      serviceTypeName: serviceTypeName,
      serviceTypeCode: serviceTypeCode,
      totalWeightGram: (shipmentMap['total_berat_gram'] as num?)?.toInt() ??
          (rawMap['total_berat_gram'] as num?)?.toInt(),
      shippingCost: (shipmentMap['biaya_pengiriman'] as num?)?.toDouble() ??
          (rawMap['biaya_pengiriman'] as num?)?.toDouble(),
      paymentMethod: shipmentMap['metode_pembayaran']?.toString() ??
          rawMap['metode_pembayaran']?.toString(),
      shippingNotes: shipmentMap['catatan_pengiriman']?.toString() ??
          rawMap['catatan_pengiriman']?.toString() ??
          assignmentMap?['catatan']?.toString(),
      currentStatusId: statusId,
      currentStatusCode: statusCode,
      currentStatusName: statusName,
      isFinalStatus: isFinal,
      assignedAt: assignedAt,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      estimatedArrival: estimatedArrival,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
        return 'Dalam Pengiriman';
      case 'AT_SORTING_CENTER':
        return 'Di Fasilitas Sortir';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar';
      case 'DELIVERED':
        return 'Terkirim';
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
      'shipmentId': shipmentId,
      'assignmentId': assignmentId,
      'trackingNumber': trackingNumber,
      'barcodeValue': barcodeValue,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderAddress': senderAddress,
      'senderCity': senderCity,
      'senderPostalCode': senderPostalCode,
      'senderLatitude': senderLatitude,
      'senderLongitude': senderLongitude,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverAddress': receiverAddress,
      'receiverCity': receiverCity,
      'receiverPostalCode': receiverPostalCode,
      'receiverLatitude': receiverLatitude,
      'receiverLongitude': receiverLongitude,
      'serviceTypeName': serviceTypeName,
      'serviceTypeCode': serviceTypeCode,
      'totalWeightGram': totalWeightGram,
      'shippingCost': shippingCost,
      'paymentMethod': paymentMethod,
      'shippingNotes': shippingNotes,
      'currentStatusId': currentStatusId,
      'currentStatusCode': currentStatusCode,
      'currentStatusName': currentStatusName,
      'isFinalStatus': isFinalStatus,
      'assignedAt': assignedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'estimatedArrival': estimatedArrival?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
