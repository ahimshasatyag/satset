import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'recipient_relationship.dart';

/// Payload parameter formulir saat kurir mengirim bukti penyerahan paket
class DeliveryProofPayload extends Equatable {
  final String shipmentId;
  final String? courierId;
  final Uint8List imageBytes;
  final String fileName;
  final String recipientName;
  final RecipientRelationship relationship;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final DateTime deliveredAt;

  const DeliveryProofPayload({
    required this.shipmentId,
    this.courierId,
    required this.imageBytes,
    required this.fileName,
    required this.recipientName,
    this.relationship = RecipientRelationship.self,
    this.notes,
    this.latitude,
    this.longitude,
    required this.deliveredAt,
  });

  /// Validasi nama penerima aktual tidak boleh kosong
  bool get isRecipientNameValid => recipientName.trim().isNotEmpty;

  /// Validasi foto bukti ada dan ukuran tidak melebihi batas 10 MB
  bool get isImageValid =>
      imageBytes.isNotEmpty && imageBytes.lengthInBytes <= 10 * 1024 * 1024;

  /// Ukuran berkas dalam format ramah pengguna (KB atau MB)
  String get formattedFileSize {
    final bytes = imageBytes.lengthInBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Catatan terpadu yang memadukan relasi penerima dan keterangan tambahan
  String get combinedNotes {
    final relLabel = relationship.label;
    final userNotes = notes?.trim() ?? '';
    if (userNotes.isNotEmpty) {
      return 'Diterima oleh: $relLabel. Catatan: $userNotes';
    }
    return 'Diterima oleh: $relLabel.';
  }

  @override
  List<Object?> get props => [
        shipmentId,
        courierId,
        imageBytes,
        fileName,
        recipientName,
        relationship,
        notes,
        latitude,
        longitude,
        deliveredAt,
      ];
}
