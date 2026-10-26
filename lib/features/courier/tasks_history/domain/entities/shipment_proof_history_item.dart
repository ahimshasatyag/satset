import 'package:equatable/equatable.dart';

/// Entitas bukti pengiriman atau serah terima barang dari [t_shipment_proofs]
class ShipmentProofHistoryItem extends Equatable {
  final String id;
  final String shipmentId;
  final String courierId;
  final String proofType; // e.g. FOTO_PAKET, TANDA_TANGAN, FOTO_PENERIMA
  final String filePath;
  final String? recipientName;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const ShipmentProofHistoryItem({
    required this.id,
    required this.shipmentId,
    required this.courierId,
    required this.proofType,
    required this.filePath,
    this.recipientName,
    this.notes,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  /// Memeriksa apakah bukti berupa foto fisik barang/penerima
  bool get isPhoto {
    final type = proofType.toUpperCase();
    return type.contains('FOTO') || type.contains('PHOTO') || type.contains('IMAGE');
  }

  /// Memeriksa apakah bukti berupa tanda tangan digital
  bool get isSignature {
    final type = proofType.toUpperCase();
    return type.contains('TANDA_TANGAN') || type.contains('SIGNATURE') || type.contains('TTD');
  }

  /// Label berbahasa Indonesia yang mudah dipahami
  String get proofTypeLabel {
    final type = proofType.toUpperCase();
    if (type == 'FOTO_PAKET') return 'Foto Paket & Lokasi';
    if (type == 'FOTO_PENERIMA') return 'Foto Penerima';
    if (type == 'TANDA_TANGAN') return 'Tanda Tangan Penerima';
    if (isSignature) return 'Tanda Tangan';
    if (isPhoto) return 'Foto Dokumentasi';
    return proofType;
  }

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        courierId,
        proofType,
        filePath,
        recipientName,
        notes,
        createdAt,
      ];
}
