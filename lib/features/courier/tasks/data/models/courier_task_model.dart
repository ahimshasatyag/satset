import '../../domain/entities/courier_task.dart';

/// Model DTO untuk [CourierTask] dengan kemampuan deserialisasi Supabase PostgreSQL & JSON
class CourierTaskModel extends CourierTask {
  const CourierTaskModel({
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
    super.notes,
    required super.assignedAt,
    super.estimatedArrival,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Factory untuk mengonversi data dari relasi Supabase [t_shipment_assignments]
  /// yang di-join dengan [t_shipments], [m_shipment_statuses], dan [m_service_types]
  factory CourierTaskModel.fromDatabase(
    Map<String, dynamic> map, {
    String? currentCourierId,
  }) {
    // 1. Ekstrak objek pengiriman (jika di-join) atau ambil langsung dari root
    final shipmentMap = (map['t_shipments'] is Map<String, dynamic>)
        ? map['t_shipments'] as Map<String, dynamic>
        : map;

    // 2. Ekstrak data status master
    final statusMap = (shipmentMap['m_shipment_statuses'] is Map<String, dynamic>)
        ? shipmentMap['m_shipment_statuses'] as Map<String, dynamic>
        : (map['m_shipment_statuses'] is Map<String, dynamic>
            ? map['m_shipment_statuses'] as Map<String, dynamic>
            : null);

    final statusId = (shipmentMap['status_id'] as num?)?.toInt() ??
        (statusMap?['id'] as num?)?.toInt() ??
        (map['status_id'] as num?)?.toInt() ??
        3;

    final statusCode = statusMap?['kode']?.toString() ??
        shipmentMap['status_code']?.toString() ??
        map['status_code']?.toString() ??
        statusCodeFromId(statusId);

    final statusName = statusMap?['nama_status']?.toString() ??
        shipmentMap['status_name']?.toString() ??
        map['status_name']?.toString() ??
        statusNameFromCode(statusCode);

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
        serviceNameFromId(serviceTypeId);

    final serviceTypeCode = serviceMap?['kode']?.toString() ??
        shipmentMap['service_type_code']?.toString() ??
        'REG';

    // 4. Resolusi Jenis Tugas (PICKUP vs DELIVERY)
    final rawAssignmentType = map['assignment_type']?.toString().toUpperCase() ??
        (statusId <= 4 ? 'PICKUP' : 'DELIVERY');
    final taskType = rawAssignmentType.contains('PICK')
        ? CourierTaskType.pickup
        : CourierTaskType.delivery;

    // 5. Resolusi ID & Penugasan
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
        (statusId >= 8 ? 'COMPLETED' : 'ASSIGNED');

    final resi = shipmentMap['nomor_resi']?.toString().trim() ??
        map['nomor_resi']?.toString().trim() ??
        'SST-UNKNOWN';

    final barcode = shipmentMap['barcode_value']?.toString().trim() ??
        map['barcode_value']?.toString().trim() ??
        resi;

    // 6. Tanggal dan Timestamp
    final assignedAt = map['assigned_at'] != null
        ? DateTime.tryParse(map['assigned_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    final estimatedArrival = shipmentMap['estimasi_tiba'] != null
        ? DateTime.tryParse(shipmentMap['estimasi_tiba'].toString())
        : (map['estimasi_tiba'] != null
            ? DateTime.tryParse(map['estimasi_tiba'].toString())
            : null);

    final completedAt = map['completed_at'] != null
        ? DateTime.tryParse(map['completed_at'].toString())
        : null;

    final createdAt = map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
        : (shipmentMap['created_at'] != null
            ? DateTime.tryParse(shipmentMap['created_at'].toString()) ?? DateTime.now()
            : DateTime.now());

    final updatedAt = map['updated_at'] != null
        ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
        : createdAt;

    // 7. Pengirim & Penerima
    final senderName = shipmentMap['pengirim_nama']?.toString() ?? 'Pengirim';
    final senderPhone = shipmentMap['pengirim_no_hp']?.toString() ?? '-';
    final senderAddress = shipmentMap['pengirim_alamat']?.toString() ?? '-';
    final senderCity = shipmentMap['pengirim_kota']?.toString() ?? 'Jakarta';
    final senderLat = (shipmentMap['pengirim_latitude'] as num?)?.toDouble();
    final senderLng = (shipmentMap['pengirim_longitude'] as num?)?.toDouble();

    final receiverName = shipmentMap['penerima_nama']?.toString() ?? 'Penerima';
    final receiverPhone = shipmentMap['penerima_no_hp']?.toString() ?? '-';
    final receiverAddress = shipmentMap['penerima_alamat']?.toString() ?? '-';
    final receiverCity = shipmentMap['penerima_kota']?.toString() ?? 'Jakarta';
    final receiverLat = (shipmentMap['penerima_latitude'] as num?)?.toDouble();
    final receiverLng = (shipmentMap['penerima_longitude'] as num?)?.toDouble();

    final weight = (shipmentMap['total_berat_gram'] as num?)?.toInt() ?? 1000;
    final itemName = shipmentMap['catatan_pengiriman']?.toString() ??
        shipmentMap['total_barang']?.toString() ??
        'Paket SatSet';
    final itemValue = (shipmentMap['nilai_barang'] as num?)?.toDouble() ?? 0.0;
    final totalFee = (shipmentMap['total_biaya'] as num?)?.toDouble() ??
        (shipmentMap['biaya_pengiriman'] as num?)?.toDouble() ??
        0.0;
    final paymentMethod = shipmentMap['metode_pembayaran']?.toString() ?? 'TRANSFER';
    final notes = map['notes']?.toString() ??
        map['catatan']?.toString() ??
        shipmentMap['catatan_pengiriman']?.toString();

    return CourierTaskModel(
      id: assignmentId,
      shipmentId: shipmentId,
      courierId: courierId,
      trackingNumber: resi,
      barcodeValue: barcode,
      taskType: taskType,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      statusDescription: statusDescriptionFromCode(statusCode, statusName),
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
      notes: notes,
      assignedAt: assignedAt,
      estimatedArrival: estimatedArrival,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Deserialisasi dari JSON
  factory CourierTaskModel.fromJson(Map<String, dynamic> json) {
    return CourierTaskModel(
      id: json['id']?.toString() ?? '',
      shipmentId: json['shipmentId']?.toString() ?? '',
      courierId: json['courierId']?.toString() ?? '',
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      barcodeValue: json['barcodeValue']?.toString() ?? '',
      taskType: json['taskType'] == 'pickup'
          ? CourierTaskType.pickup
          : CourierTaskType.delivery,
      statusId: (json['statusId'] as num?)?.toInt() ?? 1,
      statusCode: json['statusCode']?.toString() ?? 'PENDING',
      statusName: json['statusName']?.toString() ?? 'Dalam Proses',
      statusDescription: json['statusDescription']?.toString() ?? '',
      assignmentStatus: json['assignmentStatus']?.toString() ?? 'ASSIGNED',
      senderName: json['senderName']?.toString() ?? '',
      senderPhone: json['senderPhone']?.toString() ?? '',
      senderAddress: json['senderAddress']?.toString() ?? '',
      senderCity: json['senderCity']?.toString() ?? '',
      senderLatitude: (json['senderLatitude'] as num?)?.toDouble(),
      senderLongitude: (json['senderLongitude'] as num?)?.toDouble(),
      receiverName: json['receiverName']?.toString() ?? '',
      receiverPhone: json['receiverPhone']?.toString() ?? '',
      receiverAddress: json['receiverAddress']?.toString() ?? '',
      receiverCity: json['receiverCity']?.toString() ?? '',
      receiverLatitude: (json['receiverLatitude'] as num?)?.toDouble(),
      receiverLongitude: (json['receiverLongitude'] as num?)?.toDouble(),
      serviceTypeId: (json['serviceTypeId'] as num?)?.toInt() ?? 1,
      serviceTypeName: json['serviceTypeName']?.toString() ?? 'Reguler',
      serviceTypeCode: json['serviceTypeCode']?.toString() ?? 'REG',
      weightGram: (json['weightGram'] as num?)?.toInt() ?? 1000,
      itemName: json['itemName']?.toString() ?? 'Paket SatSet',
      itemValue: (json['itemValue'] as num?)?.toDouble() ?? 0.0,
      totalFee: (json['totalFee'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'TRANSFER',
      notes: json['notes']?.toString(),
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.tryParse(json['estimatedArrival'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Serialisasi ke Map / JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipmentId': shipmentId,
      'courierId': courierId,
      'trackingNumber': trackingNumber,
      'barcodeValue': barcodeValue,
      'taskType': isPickup ? 'pickup' : 'delivery',
      'statusId': statusId,
      'statusCode': statusCode,
      'statusName': statusName,
      'statusDescription': statusDescription,
      'assignmentStatus': assignmentStatus,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderAddress': senderAddress,
      'senderCity': senderCity,
      'senderLatitude': senderLatitude,
      'senderLongitude': senderLongitude,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverAddress': receiverAddress,
      'receiverCity': receiverCity,
      'receiverLatitude': receiverLatitude,
      'receiverLongitude': receiverLongitude,
      'serviceTypeId': serviceTypeId,
      'serviceTypeName': serviceTypeName,
      'serviceTypeCode': serviceTypeCode,
      'weightGram': weightGram,
      'itemName': itemName,
      'itemValue': itemValue,
      'totalFee': totalFee,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'assignedAt': assignedAt.toIso8601String(),
      'estimatedArrival': estimatedArrival?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String statusCodeFromId(int id) {
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
        return 'IN_TRANSIT';
    }
  }

  static String statusNameFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'CONFIRMED':
        return 'Terkonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Dijadwalkan untuk Pickup';
      case 'PICKED_UP':
        return 'Telah Dijemput';
      case 'IN_TRANSIT':
        return 'Dalam Perjalanan';
      case 'AT_SORTING_CENTER':
        return 'Di Pusat Sortir';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar Kurir';
      case 'DELIVERED':
        return 'Terkirim';
      case 'FAILED_DELIVERY':
        return 'Gagal Diantar';
      case 'RETURNED':
        return 'Dikembalikan';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return 'Dalam Proses';
    }
  }

  static String statusDescriptionFromCode(String code, String name) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return 'Pesanan telah dibuat dan menunggu konfirmasi penjemputan';
      case 'CONFIRMED':
        return 'Pesanan telah dikonfirmasi dan menunggu jadwal kurir';
      case 'PICKUP_SCHEDULED':
        return 'Kurir telah ditugaskan dan dijadwalkan menuju lokasi penjemputan';
      case 'PICKED_UP':
        return 'Paket telah berhasil dijemput oleh kurir dari pengirim';
      case 'IN_TRANSIT':
        return 'Paket sedang bergerak menuju fasilitas sortir atau kota tujuan';
      case 'AT_SORTING_CENTER':
        return 'Paket tiba dan sedang diproses di pusat sortir SatSet';
      case 'OUT_FOR_DELIVERY':
        return 'Kurir sedang membawa paket menuju alamat penerima';
      case 'DELIVERED':
        return 'Paket telah berhasil diserahkan kepada penerima di alamat tujuan';
      case 'FAILED_DELIVERY':
        return 'Pengantaran terkendala, kurir akan mencoba kembali';
      case 'RETURNED':
        return 'Paket dikembalikan ke pengirim karena kendala alamat';
      case 'CANCELLED':
        return 'Pesanan pengiriman dibatalkan';
      default:
        return 'Status terkini: $name';
    }
  }

  static String serviceNameFromId(int id) {
    switch (id) {
      case 1:
        return 'Reguler';
      case 2:
        return 'Express';
      case 3:
        return 'Same Day';
      case 4:
        return 'Instant Courier';
      default:
        return 'Reguler';
    }
  }
}
