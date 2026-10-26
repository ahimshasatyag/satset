import 'package:equatable/equatable.dart';

/// Jenis penugasan kurir pada riwayat
enum CourierHistoryTaskType {
  /// Semua jenis tugas
  all,

  /// Tugas penjemputan paket dari pengirim
  pickup,

  /// Tugas pengantaran paket ke penerima
  delivery,
}

/// Filter kelompok status riwayat tugas kurir
enum CourierHistoryStatusFilter {
  /// Seluruh status riwayat
  all,

  /// Tugas terkirim / selesai (DELIVERED)
  delivered,

  /// Tugas pengantaran gagal (FAILED_DELIVERY)
  failed,

  /// Tugas paket dikembalikan (RETURNED)
  returned,

  /// Tugas pengiriman dibatalkan (CANCELLED)
  cancelled,
}

/// Entitas bisnis representasi riwayat penugasan tugas kurir
class CourierTaskHistoryItem extends Equatable {
  /// ID penugasan di [t_shipment_assignments]
  final String id;

  /// ID pengiriman di [t_shipments]
  final String shipmentId;

  /// ID kurir yang ditugaskan
  final String courierId;

  /// Nomor resi unik pengiriman (mis. SST-20261022-410944)
  final String trackingNumber;

  /// Nilai barcode pengiriman
  final String barcodeValue;

  /// Jenis tugas (pickup atau delivery)
  final CourierHistoryTaskType taskType;

  /// ID status pengiriman di [m_shipment_statuses]
  final int statusId;

  /// Kode status pengiriman (DELIVERED, FAILED_DELIVERY, CANCELLED, RETURNED, dll)
  final String statusCode;

  /// Nama status pengiriman berbahasa Indonesia
  final String statusName;

  /// Deskripsi singkat status
  final String statusDescription;

  /// Status penugasan (ASSIGNED, IN_PROGRESS, COMPLETED, FAILED, CANCELLED)
  final String assignmentStatus;

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

  /// Detail Layanan & Muatan Paket
  final int serviceTypeId;
  final String serviceTypeName;
  final String serviceTypeCode;
  final int weightGram;
  final String itemName;
  final double itemValue;
  final double totalFee;
  final String paymentMethod;

  /// Metadata Waktu
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  /// Alasan kegagalan atau pengembalian (jika tercatat di database)
  final String? failureOrReturnReason;

  /// Catatan pengiriman atau penugasan
  final String? notes;

  /// Timestamp audit database
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourierTaskHistoryItem({
    required this.id,
    required this.shipmentId,
    required this.courierId,
    required this.trackingNumber,
    required this.barcodeValue,
    required this.taskType,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
    required this.statusDescription,
    required this.assignmentStatus,
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
    required this.itemName,
    required this.itemValue,
    required this.totalFee,
    required this.paymentMethod,
    required this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.completedAt,
    this.failureOrReturnReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True jika tugas adalah pengambilan paket
  bool get isPickup => taskType == CourierHistoryTaskType.pickup;

  /// True jika tugas adalah pengantaran paket
  bool get isDelivery => taskType == CourierHistoryTaskType.delivery;

  /// True jika tugas berstatus berhasil diterima
  bool get isDelivered => statusCode.toUpperCase() == 'DELIVERED';

  /// True jika tugas pengantaran mengalami kegagalan
  bool get isFailed => statusCode.toUpperCase() == 'FAILED_DELIVERY';

  /// True jika paket berstatus dikembalikan ke pengirim
  bool get isReturned => statusCode.toUpperCase() == 'RETURNED';

  /// True jika tugas dibatalkan
  bool get isCancelled => statusCode.toUpperCase() == 'CANCELLED';

  /// Label deskriptif jenis tugas
  String get taskTypeLabel => isPickup ? 'Pengambilan' : 'Pengantaran';

  /// Nama pihak target (pengirim jika pickup, penerima jika delivery)
  String get targetPersonName => isPickup ? senderName : receiverName;

  /// Nomor telepon pihak target
  String get targetPersonPhone => isPickup ? senderPhone : receiverPhone;

  /// Alamat tujuan aktivitas kurir
  String get targetAddress => isPickup ? senderAddress : receiverAddress;

  /// Kota tujuan aktivitas kurir
  String get targetCity => isPickup ? senderCity : receiverCity;

  /// Bobot paket terformat dalam Kilogram (kg)
  String get weightFormatted => '${(weightGram / 1000).toStringAsFixed(1)} kg';

  /// Timestamp penyelesaian utama tugas (completed_at atau delivered_at atau cancelled_at)
  DateTime get primaryCompletionTime =>
      completedAt ?? deliveredAt ?? cancelledAt ?? updatedAt;

  /// Memeriksa apakah ada alasan kegagalan / pengembalian yang tercatat
  bool get hasFailureReason =>
      (isFailed || isReturned || isCancelled) &&
      failureOrReturnReason != null &&
      failureOrReturnReason!.trim().isNotEmpty;

  CourierTaskHistoryItem copyWith({
    String? id,
    String? shipmentId,
    String? courierId,
    String? trackingNumber,
    String? barcodeValue,
    CourierHistoryTaskType? taskType,
    int? statusId,
    String? statusCode,
    String? statusName,
    String? statusDescription,
    String? assignmentStatus,
    String? senderName,
    String? senderPhone,
    String? senderAddress,
    String? senderCity,
    double? senderLatitude,
    double? senderLongitude,
    String? receiverName,
    String? receiverPhone,
    String? receiverAddress,
    String? receiverCity,
    double? receiverLatitude,
    double? receiverLongitude,
    int? serviceTypeId,
    String? serviceTypeName,
    String? serviceTypeCode,
    int? weightGram,
    String? itemName,
    double? itemValue,
    double? totalFee,
    String? paymentMethod,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
    String? failureOrReturnReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourierTaskHistoryItem(
      id: id ?? this.id,
      shipmentId: shipmentId ?? this.shipmentId,
      courierId: courierId ?? this.courierId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      taskType: taskType ?? this.taskType,
      statusId: statusId ?? this.statusId,
      statusCode: statusCode ?? this.statusCode,
      statusName: statusName ?? this.statusName,
      statusDescription: statusDescription ?? this.statusDescription,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      senderAddress: senderAddress ?? this.senderAddress,
      senderCity: senderCity ?? this.senderCity,
      senderLatitude: senderLatitude ?? this.senderLatitude,
      senderLongitude: senderLongitude ?? this.senderLongitude,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      receiverCity: receiverCity ?? this.receiverCity,
      receiverLatitude: receiverLatitude ?? this.receiverLatitude,
      receiverLongitude: receiverLongitude ?? this.receiverLongitude,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      serviceTypeName: serviceTypeName ?? this.serviceTypeName,
      serviceTypeCode: serviceTypeCode ?? this.serviceTypeCode,
      weightGram: weightGram ?? this.weightGram,
      itemName: itemName ?? this.itemName,
      itemValue: itemValue ?? this.itemValue,
      totalFee: totalFee ?? this.totalFee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      failureOrReturnReason: failureOrReturnReason ?? this.failureOrReturnReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        courierId,
        trackingNumber,
        barcodeValue,
        taskType,
        statusId,
        statusCode,
        statusName,
        assignmentStatus,
        assignedAt,
        completedAt,
        deliveredAt,
        failureOrReturnReason,
        createdAt,
        updatedAt,
      ];
}
