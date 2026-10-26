import 'package:equatable/equatable.dart';

/// Opsi perubahan status tugas yang sah secara operasional sesuai aturan bisnis SatSet Delivery
class StatusTransitionOption extends Equatable {
  final String statusCode;
  final String statusName;
  final int targetStatusId;
  final String actionTitle;
  final String description;
  final bool requiresProof;
  final bool requiresFailureReason;
  final bool isDestructive;

  const StatusTransitionOption({
    required this.statusCode,
    required this.statusName,
    required this.targetStatusId,
    required this.actionTitle,
    required this.description,
    this.requiresProof = false,
    this.requiresFailureReason = false,
    this.isDestructive = false,
  });

  /// Factory untuk memetakan transisi standar berdasarkan kode status tujuan
  factory StatusTransitionOption.forCode(String code) {
    switch (code.toUpperCase()) {
      case 'PICKUP_SCHEDULED':
        return const StatusTransitionOption(
          statusCode: 'PICKUP_SCHEDULED',
          statusName: 'Menunggu Penjemputan',
          targetStatusId: 3,
          actionTitle: 'Jadwalkan Penjemputan',
          description: 'Konfirmasi bahwa kurir sedang bersiap menjemput paket dari pengirim.',
        );

      case 'PICKED_UP':
        return const StatusTransitionOption(
          statusCode: 'PICKED_UP',
          statusName: 'Paket Dijemput',
          targetStatusId: 4,
          actionTitle: 'Tandai Paket Dijemput',
          description: 'Paket telah berhasil diserahterimakan dari pihak pengirim ke kurir.',
        );

      case 'IN_TRANSIT':
        return const StatusTransitionOption(
          statusCode: 'IN_TRANSIT',
          statusName: 'Dalam Perjalanan',
          targetStatusId: 5,
          actionTitle: 'Bawa ke Fasilitas Sortir',
          description: 'Paket sedang dibawa menuju fasilitas sortir atau diteruskan ke hub berikutnya.',
        );

      case 'AT_SORTING_CENTER':
        return const StatusTransitionOption(
          statusCode: 'AT_SORTING_CENTER',
          statusName: 'Tiba di Gudang Sortir',
          targetStatusId: 6,
          actionTitle: 'Serahkan ke Gudang Sortir',
          description: 'Paket tiba dan diserahterimakan ke petugas fasilitas sortir.',
        );

      case 'OUT_FOR_DELIVERY':
        return const StatusTransitionOption(
          statusCode: 'OUT_FOR_DELIVERY',
          statusName: 'Sedang Diantar',
          targetStatusId: 7,
          actionTitle: 'Mulai Pengantaran ke Penerima',
          description: 'Kurir mulai bergerak mengantar paket langsung ke alamat penerima.',
        );

      case 'DELIVERED':
        return const StatusTransitionOption(
          statusCode: 'DELIVERED',
          statusName: 'Paket Diterima',
          targetStatusId: 8,
          actionTitle: 'Selesaikan & Unggah Bukti',
          description: 'Paket berhasil diserahkan kepada penerima. Wajib melampirkan bukti pengiriman.',
          requiresProof: true,
        );

      case 'FAILED_DELIVERY':
        return const StatusTransitionOption(
          statusCode: 'FAILED_DELIVERY',
          statusName: 'Pengantaran Gagal',
          targetStatusId: 9,
          actionTitle: 'Laporkan Gagal Diantar',
          description: 'Paket tidak dapat diserahkan karena kendala di lokasi penerima.',
          requiresFailureReason: true,
          isDestructive: true,
        );

      default:
        return StatusTransitionOption(
          statusCode: code,
          statusName: code,
          targetStatusId: 0,
          actionTitle: 'Perbarui ke $code',
          description: 'Perbarui status operasional paket.',
        );
    }
  }

  @override
  List<Object?> get props => [
        statusCode,
        statusName,
        targetStatusId,
        actionTitle,
        description,
        requiresProof,
        requiresFailureReason,
        isDestructive,
      ];
}
