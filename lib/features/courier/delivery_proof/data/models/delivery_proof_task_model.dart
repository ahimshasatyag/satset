import '../../domain/entities/delivery_proof_task.dart';

class DeliveryProofTaskModel extends DeliveryProofTask {
  const DeliveryProofTaskModel({
    required super.shipmentId,
    required super.assignmentId,
    required super.trackingNumber,
    super.barcodeValue,
    required super.receiverName,
    required super.receiverPhone,
    required super.receiverAddress,
    required super.receiverCity,
    super.serviceTypeName,
    required super.currentStatusId,
    required super.currentStatusCode,
    required super.currentStatusName,
    super.notes,
    super.assignedAt,
  });

  factory DeliveryProofTaskModel.fromDatabase(Map<String, dynamic> map) {
    // Penanganan relasi t_shipments yang mungkin ter-nesting dari join Supabase
    final shipmentData = map['t_shipments'] is Map<String, dynamic>
        ? map['t_shipments'] as Map<String, dynamic>
        : map;

    final statusData = shipmentData['m_shipment_statuses'] is Map<String, dynamic>
        ? shipmentData['m_shipment_statuses'] as Map<String, dynamic>
        : <String, dynamic>{};

    final serviceTypeData = shipmentData['m_service_types'] is Map<String, dynamic>
        ? shipmentData['m_service_types'] as Map<String, dynamic>
        : <String, dynamic>{};

    return DeliveryProofTaskModel(
      shipmentId: (shipmentData['id'] ?? map['shipment_id'] ?? '').toString(),
      assignmentId: (map['id'] ?? '').toString(),
      trackingNumber: (shipmentData['nomor_resi'] ?? '').toString(),
      barcodeValue: shipmentData['barcode_value']?.toString(),
      receiverName: (shipmentData['penerima_nama'] ?? 'Penerima').toString(),
      receiverPhone: (shipmentData['penerima_no_hp'] ?? '').toString(),
      receiverAddress: (shipmentData['penerima_alamat'] ?? '').toString(),
      receiverCity: (shipmentData['penerima_kota'] ?? '').toString(),
      serviceTypeName: serviceTypeData['nama_layanan']?.toString(),
      currentStatusId: int.tryParse(shipmentData['status_id']?.toString() ?? '7') ?? 7,
      currentStatusCode: (statusData['kode'] ?? 'OUT_FOR_DELIVERY').toString(),
      currentStatusName: (statusData['nama_status'] ?? 'Sedang Diantar').toString(),
      notes: shipmentData['catatan_pengiriman']?.toString(),
      assignedAt: map['assigned_at'] != null
          ? DateTime.tryParse(map['assigned_at'].toString())
          : null,
    );
  }

  factory DeliveryProofTaskModel.fromJson(Map<String, dynamic> json) {
    return DeliveryProofTaskModel(
      shipmentId: json['shipment_id']?.toString() ?? '',
      assignmentId: json['assignment_id']?.toString() ?? '',
      trackingNumber: json['nomor_resi']?.toString() ?? '',
      barcodeValue: json['barcode_value']?.toString(),
      receiverName: json['penerima_nama']?.toString() ?? '',
      receiverPhone: json['penerima_no_hp']?.toString() ?? '',
      receiverAddress: json['penerima_alamat']?.toString() ?? '',
      receiverCity: json['penerima_kota']?.toString() ?? '',
      serviceTypeName: json['nama_layanan']?.toString(),
      currentStatusId: json['status_id'] is int ? json['status_id'] : 7,
      currentStatusCode: json['status_code']?.toString() ?? 'OUT_FOR_DELIVERY',
      currentStatusName: json['status_name']?.toString() ?? 'Sedang Diantar',
      notes: json['notes']?.toString(),
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shipment_id': shipmentId,
      'assignment_id': assignmentId,
      'nomor_resi': trackingNumber,
      'barcode_value': barcodeValue,
      'penerima_nama': receiverName,
      'penerima_no_hp': receiverPhone,
      'penerima_alamat': receiverAddress,
      'penerima_kota': receiverCity,
      'nama_layanan': serviceTypeName,
      'status_id': currentStatusId,
      'status_code': currentStatusCode,
      'status_name': currentStatusName,
      'notes': notes,
      'assigned_at': assignedAt?.toIso8601String(),
    };
  }
}
