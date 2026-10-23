import 'package:equatable/equatable.dart';

/// Jenis proses operasional paket saat pemindaian barcode kurir
enum BarcodeScanProcessType {
  /// Proses pengambilan paket dari pengirim
  pickup,

  /// Proses serah terima / transit di sorting center / hub
  inTransit,

  /// Proses pengantaran paket ke tangan penerima
  outForDelivery,

  /// Paket telah sukses diantar ke penerima
  delivered,

  /// Pengiriman mengalami kendala atau gagal
  problem,

  /// Status tidak dikenal atau belum siap diproses
  unknown,
}

/// Entitas paket pengiriman hasil pemindaian barcode kurir
class ScannedShipment extends Equatable {
  /// ID pengiriman di tabel [t_shipments]
  final String shipmentId;

  /// ID penugasan kurir di tabel [t_shipment_assignments] (bisa null jika belum ditugaskan)
  final String? assignmentId;

  /// ID kurir yang ditugaskan (jika ada)
  final String? assignedCourierId;

  /// Nomor resi unik pengiriman (mis. SST-20261023-001)
  final String trackingNumber;

  /// Nilai barcode yang tercetak pada label paket
  final String barcodeValue;

  /// ID status pengiriman di tabel [m_shipment_statuses]
  final int statusId;

  /// Kode status pengiriman (mis. PICKUP_SCHEDULED, OUT_FOR_DELIVERY, DELIVERED)
  final String statusCode;

  /// Label nama status pengiriman dalam Bahasa Indonesia
  final String statusName;

  /// Deskripsi singkat status
  final String statusDescription;

  /// Data Pengirim
  final String senderName;
  final String senderPhone;
  final String senderAddress;
  final String senderCity;
  final double? senderLatitude;
  final double? senderLongitude;

  /// Data Penerima
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String receiverCity;
  final double? receiverLatitude;
  final double? receiverLongitude;

  /// Detail Layanan & Dimensi Paket
  final int serviceTypeId;
  final String serviceTypeName;
  final String serviceTypeCode;
  final int weightGram;
  final String? notes;

  /// Metadata waktu
  final DateTime? estimatedArrival;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Flag penugasan terhadap kurir yang sedang aktif login
  final bool isAssignedToActiveCourier;

  const ScannedShipment({
    required this.shipmentId,
    this.assignmentId,
    this.assignedCourierId,
    required this.trackingNumber,
    required this.barcodeValue,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
    required this.statusDescription,
    required this.senderName,
    required this.senderPhone,
    required this.senderAddress,
    required this.senderCity,
    this.senderLatitude,
    this.senderLongitude,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.receiverCity,
    this.receiverLatitude,
    this.receiverLongitude,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.serviceTypeCode,
    required this.weightGram,
    this.notes,
    this.estimatedArrival,
    this.pickedUpAt,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isAssignedToActiveCourier,
  });

  /// Mengidentifikasi jenis proses operasional berdasarkan status kode pengiriman
  BarcodeScanProcessType get processType {
    final code = statusCode.toUpperCase();
    if (code == 'PENDING' || code == 'CONFIRMED' || code == 'PICKUP_SCHEDULED') {
      return BarcodeScanProcessType.pickup;
    }
    if (code == 'PICKED_UP' || code == 'IN_TRANSIT' || code == 'AT_SORTING_CENTER') {
      return BarcodeScanProcessType.inTransit;
    }
    if (code == 'OUT_FOR_DELIVERY') {
      return BarcodeScanProcessType.outForDelivery;
    }
    if (code == 'DELIVERED') {
      return BarcodeScanProcessType.delivered;
    }
    if (code == 'FAILED_DELIVERY' || code == 'RETURNED' || code == 'CANCELLED') {
      return BarcodeScanProcessType.problem;
    }
    return BarcodeScanProcessType.unknown;
  }

  /// Label Bahasa Indonesia untuk jenis proses operasional
  String get processTypeLabel {
    switch (processType) {
      case BarcodeScanProcessType.pickup:
        return 'Penjemputan (Pickup)';
      case BarcodeScanProcessType.inTransit:
        return 'Penerimaan / Transit Hub';
      case BarcodeScanProcessType.outForDelivery:
        return 'Pengantaran (Delivery)';
      case BarcodeScanProcessType.delivered:
        return 'Selesai Terkirim';
      case BarcodeScanProcessType.problem:
        return 'Kendala Pengiriman';
      case BarcodeScanProcessType.unknown:
        return 'Pemeriksaan Paket';
    }
  }

  /// Nama pihak target yang relevan dengan proses saat ini
  /// (Pengirim jika pickup, Penerima jika pengantaran/transit)
  String get contextPersonName {
    return processType == BarcodeScanProcessType.pickup ? senderName : receiverName;
  }

  /// Label peran pihak target (Pengirim / Penerima)
  String get contextPersonRoleLabel {
    return processType == BarcodeScanProcessType.pickup ? 'Pengirim' : 'Penerima';
  }

  /// Nomor telepon pihak target
  String get contextPersonPhone {
    return processType == BarcodeScanProcessType.pickup ? senderPhone : receiverPhone;
  }

  /// Alamat tujuan kontekstual
  String get contextAddress {
    return processType == BarcodeScanProcessType.pickup ? senderAddress : receiverAddress;
  }

  /// Kota kontekstual
  String get contextCity {
    return processType == BarcodeScanProcessType.pickup ? senderCity : receiverCity;
  }

  /// Format berat paket dalam kilogram (kg)
  String get formattedWeight => '${(weightGram / 1000).toStringAsFixed(1)} kg';

  /// Apakah status saat ini diizinkan untuk diproses oleh kurir
  bool get isStatusPermittedForAction {
    final code = statusCode.toUpperCase();
    // Status yang siap diproses:
    // 1. Pickup: PENDING, CONFIRMED, PICKUP_SCHEDULED -> boleh konfirmasi PICKED_UP
    // 2. Transit: PICKED_UP, IN_TRANSIT, AT_SORTING_CENTER -> boleh serah terima / OUT_FOR_DELIVERY
    // 3. Delivery: OUT_FOR_DELIVERY -> boleh DELIVERED / FAILED_DELIVERY
    // Status yang TIDAK boleh diproses lagi: DELIVERED, CANCELLED, RETURNED
    if (code == 'DELIVERED') return false;
    if (code == 'CANCELLED') return false;
    if (code == 'RETURNED') return false;
    return true;
  }

  /// Status kode target berikutnya yang direkomendasikan
  String? get recommendedActionStatusCode {
    final code = statusCode.toUpperCase();
    switch (code) {
      case 'PENDING':
      case 'CONFIRMED':
      case 'PICKUP_SCHEDULED':
        return 'PICKED_UP';
      case 'PICKED_UP':
      case 'AT_SORTING_CENTER':
        return 'IN_TRANSIT';
      case 'IN_TRANSIT':
        return 'OUT_FOR_DELIVERY';
      case 'OUT_FOR_DELIVERY':
        return 'DELIVERED';
      case 'FAILED_DELIVERY':
        return 'OUT_FOR_DELIVERY';
      default:
        return null;
    }
  }

  /// Label tombol aksi operasional berikutnya
  String? get recommendedActionLabel {
    final targetCode = recommendedActionStatusCode;
    if (targetCode == null) return null;
    switch (targetCode) {
      case 'PICKED_UP':
        return 'Konfirmasi Pickup Paket';
      case 'IN_TRANSIT':
        return 'Serah Terima ke Hub';
      case 'OUT_FOR_DELIVERY':
        return 'Mulai Antar ke Penerima';
      case 'DELIVERED':
        return 'Konfirmasi Paket Terkirim';
      default:
        return 'Proses Status ($targetCode)';
    }
  }

  /// Daftar opsi status valid selanjutnya
  List<String> get validNextStatuses {
    final code = statusCode.toUpperCase();
    switch (code) {
      case 'PENDING':
      case 'CONFIRMED':
      case 'PICKUP_SCHEDULED':
        return const ['PICKED_UP'];
      case 'PICKED_UP':
        return const ['IN_TRANSIT'];
      case 'IN_TRANSIT':
      case 'AT_SORTING_CENTER':
        return const ['OUT_FOR_DELIVERY'];
      case 'OUT_FOR_DELIVERY':
        return const ['DELIVERED', 'FAILED_DELIVERY'];
      case 'FAILED_DELIVERY':
        return const ['OUT_FOR_DELIVERY', 'RETURNED'];
      default:
        return const [];
    }
  }

  @override
  List<Object?> get props => [
        shipmentId,
        assignmentId,
        assignedCourierId,
        trackingNumber,
        barcodeValue,
        statusId,
        statusCode,
        statusName,
        senderName,
        receiverName,
        serviceTypeId,
        weightGram,
        isAssignedToActiveCourier,
      ];
}
