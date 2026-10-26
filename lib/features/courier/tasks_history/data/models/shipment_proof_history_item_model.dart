import '../../domain/entities/shipment_proof_history_item.dart';

/// Model implementasi [ShipmentProofHistoryItem] dengan pemetaan data [t_shipment_proofs]
class ShipmentProofHistoryItemModel extends ShipmentProofHistoryItem {
  const ShipmentProofHistoryItemModel({
    required super.id,
    required super.shipmentId,
    required super.courierId,
    required super.proofType,
    required super.filePath,
    super.recipientName,
    super.notes,
    super.latitude,
    super.longitude,
    required super.createdAt,
  });

  factory ShipmentProofHistoryItemModel.fromDatabase(Map<String, dynamic> map) {
    return ShipmentProofHistoryItemModel(
      id: map['id']?.toString() ?? '',
      shipmentId: map['shipment_id']?.toString() ?? '',
      courierId: map['courier_id']?.toString() ?? '',
      proofType: map['jenis_bukti']?.toString() ?? 'FOTO_PAKET',
      filePath: map['file_path']?.toString() ?? '',
      recipientName: map['penerima_nama']?.toString(),
      notes: map['catatan']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory ShipmentProofHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return ShipmentProofHistoryItemModel(
      id: json['id']?.toString() ?? '',
      shipmentId: json['shipment_id']?.toString() ?? '',
      courierId: json['courier_id']?.toString() ?? '',
      proofType: json['jenis_bukti']?.toString() ?? 'FOTO_PAKET',
      filePath: json['file_path']?.toString() ?? '',
      recipientName: json['penerima_nama']?.toString(),
      notes: json['catatan']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'courier_id': courierId,
      'jenis_bukti': proofType,
      'file_path': filePath,
      'penerima_nama': recipientName,
      'catatan': notes,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
