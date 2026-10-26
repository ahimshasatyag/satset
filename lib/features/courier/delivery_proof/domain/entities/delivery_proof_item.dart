import 'package:equatable/equatable.dart';
import 'recipient_relationship.dart';

/// Entity data bukti pengiriman yang tersimpan di tabel `t_shipment_proofs`
class DeliveryProofItem extends Equatable {
  final String? id;
  final String shipmentId;
  final String courierId;
  final String proofType;
  final String filePath;
  final String recipientName;
  final RecipientRelationship relationship;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const DeliveryProofItem({
    this.id,
    required this.shipmentId,
    required this.courierId,
    this.proofType = 'FOTO_PENYERAHAN',
    required this.filePath,
    required this.recipientName,
    this.relationship = RecipientRelationship.self,
    this.notes,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  /// True jika bukti dilengkapi koordinat GPS penyerahan aktual
  bool get hasLocationCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude != 0.0 &&
      longitude != 0.0;

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        courierId,
        proofType,
        filePath,
        recipientName,
        relationship,
        notes,
        latitude,
        longitude,
        createdAt,
      ];
}
