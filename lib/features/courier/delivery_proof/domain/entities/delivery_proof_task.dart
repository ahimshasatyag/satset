import 'package:equatable/equatable.dart';

/// Entity representasi tugas pengantaran yang sedang atau akan diserahkan oleh kurir.
/// Memuat informasi resi, penerima terdaftar, status pengiriman terkini, serta alamat tujuan.
class DeliveryProofTask extends Equatable {
  final String shipmentId;
  final String assignmentId;
  final String trackingNumber;
  final String? barcodeValue;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String receiverCity;
  final String? serviceTypeName;
  final int currentStatusId;
  final String currentStatusCode;
  final String currentStatusName;
  final String? notes;
  final DateTime? assignedAt;

  const DeliveryProofTask({
    required this.shipmentId,
    required this.assignmentId,
    required this.trackingNumber,
    this.barcodeValue,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.receiverCity,
    this.serviceTypeName,
    required this.currentStatusId,
    required this.currentStatusCode,
    required this.currentStatusName,
    this.notes,
    this.assignedAt,
  });

  /// True jika paket sudah pernah diserahkan / berstatus DELIVERED
  bool get isDelivered => currentStatusCode.toUpperCase() == 'DELIVERED';

  /// True jika tugas dapat dikirimkan bukti pengirimannya
  bool get canSubmitProof => !isDelivered;

  /// Teks alamat lengkap tujuan
  String get fullDestinationAddress {
    if (receiverCity.isNotEmpty) {
      return '$receiverAddress, $receiverCity';
    }
    return receiverAddress;
  }

  @override
  List<Object?> get props => [
        shipmentId,
        assignmentId,
        trackingNumber,
        barcodeValue,
        receiverName,
        receiverPhone,
        receiverAddress,
        receiverCity,
        serviceTypeName,
        currentStatusId,
        currentStatusCode,
        currentStatusName,
        notes,
        assignedAt,
      ];
}
