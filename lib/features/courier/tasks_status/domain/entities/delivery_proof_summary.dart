import 'package:equatable/equatable.dart';

/// Entity ringkasan data bukti penyerahan paket yang tersimpan di `t_shipment_proofs`
class DeliveryProofSummary extends Equatable {
  final String id;
  final String shipmentId;
  final String courierId;
  final String proofType;
  final String filePath;
  final String recipientName;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const DeliveryProofSummary({
    required this.id,
    required this.shipmentId,
    required this.courierId,
    this.proofType = 'FOTO_PENYERAHAN',
    required this.filePath,
    required this.recipientName,
    this.notes,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  /// True jika berkas berupa foto bukti yang dapat ditampilkan
  bool get hasValidPhoto => filePath.isNotEmpty;

  /// True jika memuat koordinat GPS
  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        courierId,
        proofType,
        filePath,
        recipientName,
        notes,
        latitude,
        longitude,
        createdAt,
      ];
}
