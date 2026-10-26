import '../../domain/entities/delivery_proof_summary.dart';

/// Model untuk [DeliveryProofSummary] yang memetakan data dari tabel `t_shipment_proofs`
class DeliveryProofSummaryModel extends DeliveryProofSummary {
  const DeliveryProofSummaryModel({
    required super.id,
    required super.shipmentId,
    required super.courierId,
    super.proofType = 'FOTO_PENYERAHAN',
    required super.filePath,
    required super.recipientName,
    super.notes,
    super.latitude,
    super.longitude,
    required super.createdAt,
  });

  /// Factory untuk memetakan dari query Supabase tabel `t_shipment_proofs`
  factory DeliveryProofSummaryModel.fromDatabase(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['created_at'] != null) {
      parsedDate = DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return DeliveryProofSummaryModel(
      id: map['id']?.toString() ?? '',
      shipmentId: map['shipment_id']?.toString() ?? '',
      courierId: map['courier_id']?.toString() ?? '',
      proofType: map['jenis_bukti']?.toString() ?? 'FOTO_PENYERAHAN',
      filePath: map['file_path']?.toString() ?? '',
      recipientName: map['penerima_nama']?.toString() ?? '-',
      notes: map['catatan']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipmentId': shipmentId,
      'courierId': courierId,
      'proofType': proofType,
      'filePath': filePath,
      'recipientName': recipientName,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
