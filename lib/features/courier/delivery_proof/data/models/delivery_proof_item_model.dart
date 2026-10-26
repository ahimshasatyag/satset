import '../../domain/entities/delivery_proof_item.dart';
import '../../domain/entities/recipient_relationship.dart';

class DeliveryProofItemModel extends DeliveryProofItem {
  const DeliveryProofItemModel({
    super.id,
    required super.shipmentId,
    required super.courierId,
    super.proofType = 'FOTO_PENYERAHAN',
    required super.filePath,
    required super.recipientName,
    super.relationship = RecipientRelationship.self,
    super.notes,
    super.latitude,
    super.longitude,
    required super.createdAt,
  });

  factory DeliveryProofItemModel.fromDatabase(Map<String, dynamic> map) {
    final rawNotes = map['catatan']?.toString();
    RecipientRelationship rel = RecipientRelationship.self;

    // Ekstraksi relasi penerima jika tersimpan dalam format terstruktur di catatan
    if (rawNotes != null) {
      for (final candidate in RecipientRelationship.values) {
        if (rawNotes.contains(candidate.label) || rawNotes.contains(candidate.code)) {
          rel = candidate;
          break;
        }
      }
    }

    return DeliveryProofItemModel(
      id: map['id']?.toString(),
      shipmentId: (map['shipment_id'] ?? '').toString(),
      courierId: (map['courier_id'] ?? '').toString(),
      proofType: (map['jenis_bukti'] ?? 'FOTO_PENYERAHAN').toString(),
      filePath: (map['file_path'] ?? '').toString(),
      recipientName: (map['penerima_nama'] ?? '').toString(),
      relationship: rel,
      notes: rawNotes,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory DeliveryProofItemModel.fromEntity(DeliveryProofItem entity) {
    return DeliveryProofItemModel(
      id: entity.id,
      shipmentId: entity.shipmentId,
      courierId: entity.courierId,
      proofType: entity.proofType,
      filePath: entity.filePath,
      recipientName: entity.recipientName,
      relationship: entity.relationship,
      notes: entity.notes,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toDatabaseInsert() {
    return {
      'shipment_id': int.tryParse(shipmentId) ?? shipmentId,
      'courier_id': int.tryParse(courierId) ?? courierId,
      'jenis_bukti': proofType,
      'file_path': filePath,
      'penerima_nama': recipientName,
      'catatan': notes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'courier_id': courierId,
      'jenis_bukti': proofType,
      'file_path': filePath,
      'penerima_nama': recipientName,
      'relationship': relationship.code,
      'catatan': notes,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
