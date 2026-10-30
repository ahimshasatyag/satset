import 'package:equatable/equatable.dart';

/// Jenis penugasan kurir (Pengambilan atau Pengantaran)
enum CourierTaskType {
  /// Tugas penjemputan paket dari pengirim
  pickup,

  /// Tugas pengantaran paket ke penerima
  delivery,
}

/// Kelompok filter tugas kurir
enum CourierTaskGroup {
  /// Tugas yang perlu dikerjakan (dijadwalkan / baru ditugaskan)
  pending,

  /// Tugas yang sedang berlangsung (sedang dijemput / dalam perjalanan / diantar)
  inProgress,

  /// Tugas yang telah selesai (terkirim / selesai / kendala)
  completed,
}

/// Entitas bisnis inti yang merepresentasikan tugas penugasan pengiriman bagi kurir
class CourierTask extends Equatable {
  /// ID penugasan kurir di tabel [t_shipment_assignments]
  final String id;

  /// ID pengiriman di tabel [t_shipments]
  final String shipmentId;

  /// ID kurir yang bertugas (mengacu pada [m_users.id])
  final String courierId;

  /// Nomor resi unik pengiriman (mis. SST-20261021-001)
  final String trackingNumber;

  /// Nilai barcode untuk pemindaian scanner
  final String barcodeValue;

  /// Jenis aktivitas tugas: pickup atau delivery
  final CourierTaskType taskType;

  /// ID status pengiriman di [m_shipment_statuses]
  final int statusId;

  /// Kode status pengiriman (mis. PICKUP_SCHEDULED, OUT_FOR_DELIVERY, DELIVERED)
  final String statusCode;

  /// Nama status pengiriman (Bahasa Indonesia)
  final String statusName;

  /// Penjelasan ringkas status pengiriman
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

  /// Detail Layanan & Paket
  final int serviceTypeId;
  final String serviceTypeName;
  final String serviceTypeCode;
  final int weightGram;
  final String itemName;
  final double itemValue;
  final double totalFee;
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;

  /// Metadata Waktu
  final DateTime assignedAt;
  final DateTime? estimatedArrival;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourierTask({
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
    this.paymentStatus = 'PENDING',
    this.notes,
    required this.assignedAt,
    this.estimatedArrival,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Mengidentifikasi apakah tugas adalah penjemputan paket
  bool get isPickup => taskType == CourierTaskType.pickup;

  /// Mengidentifikasi apakah tugas adalah pengantaran paket
  bool get isDelivery => taskType == CourierTaskType.delivery;

  /// Menentukan kelompok tugas kurir
  CourierTaskGroup get taskGroup {
    final code = statusCode.toUpperCase();
    final assignStat = assignmentStatus.toUpperCase();

    if (code == 'DELIVERED' ||
        code == 'FAILED_DELIVERY' ||
        code == 'RETURNED' ||
        code == 'CANCELLED' ||
        assignStat == 'COMPLETED' ||
        assignStat == 'CANCELLED') {
      return CourierTaskGroup.completed;
    }

    if (code == 'PICKED_UP' ||
        code == 'IN_TRANSIT' ||
        code == 'OUT_FOR_DELIVERY' ||
        assignStat == 'IN_PROGRESS') {
      return CourierTaskGroup.inProgress;
    }

    // Default: PENDING / CONFIRMED / PICKUP_SCHEDULED / ASSIGNED
    return CourierTaskGroup.pending;
  }

  /// Nama pihak target yang harus ditemui kurir
  String get targetPersonName => isPickup ? senderName : receiverName;

  /// Nomor telepon pihak target
  String get targetPersonPhone => isPickup ? senderPhone : receiverPhone;

  /// Alamat tujuan aktivitas kurir saat ini
  String get targetAddress => isPickup ? senderAddress : receiverAddress;

  /// Kota tujuan aktivitas kurir
  String get targetCity => isPickup ? senderCity : receiverCity;

  /// Koordinat latitude tujuan
  double? get targetLatitude => isPickup ? senderLatitude : receiverLatitude;

  /// Koordinat longitude tujuan
  double? get targetLongitude => isPickup ? senderLongitude : receiverLongitude;

  /// Label deskriptif tipe tugas
  String get taskTypeLabel => isPickup ? 'Pengambilan (Pickup)' : 'Pengantaran (Delivery)';

  /// Bobot paket terformat dalam Kilogram (kg)
  String get weightFormatted => '${(weightGram / 1000).toStringAsFixed(1)} kg';

  /// True jika pembayaran sudah selesai (Lunas / Settled / COD)
  bool get isPaid =>
      paymentStatus.toUpperCase() == 'PAID' ||
      paymentStatus.toUpperCase() == 'SETTLED' ||
      paymentMethod.toUpperCase() == 'COD';

  /// True jika paket masih menunggu pembayaran dari pelanggan
  bool get isWaitingPayment => !isPaid;

  /// Daftar status alur berikutnya yang diizinkan untuk tugas ini
  List<String> get validNextStatuses {
    // Jika masih menunggu pembayaran, paket belum bisa dijemput, dalam perjalanan, diproses, atau diantar!
    if (isWaitingPayment) {
      return const [];
    }
    final code = statusCode.toUpperCase();
    if (isPickup) {
      if (code == 'PICKUP_SCHEDULED' || code == 'CONFIRMED' || code == 'PENDING') {
        return const ['PICKED_UP'];
      }
      if (code == 'PICKED_UP') {
        return const ['IN_TRANSIT'];
      }
    } else {
      if (code == 'IN_TRANSIT' || code == 'AT_SORTING_CENTER') {
        return const ['OUT_FOR_DELIVERY'];
      }
      if (code == 'OUT_FOR_DELIVERY') {
        return const ['DELIVERED', 'FAILED_DELIVERY'];
      }
      if (code == 'FAILED_DELIVERY') {
        return const ['OUT_FOR_DELIVERY', 'RETURNED'];
      }
    }
    return const [];
  }

  CourierTask copyWith({
    String? id,
    String? shipmentId,
    String? courierId,
    String? trackingNumber,
    String? barcodeValue,
    CourierTaskType? taskType,
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
    String? paymentStatus,
    String? notes,
    DateTime? assignedAt,
    DateTime? estimatedArrival,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourierTask(
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
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      assignedAt: assignedAt ?? this.assignedAt,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      completedAt: completedAt ?? this.completedAt,
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
        senderName,
        senderPhone,
        senderAddress,
        senderCity,
        receiverName,
        receiverPhone,
        receiverAddress,
        receiverCity,
        serviceTypeId,
        serviceTypeName,
        weightGram,
        itemName,
        totalFee,
        paymentMethod,
        paymentStatus,
        notes,
        assignedAt,
        estimatedArrival,
        completedAt,
        createdAt,
        updatedAt,
      ];
}
