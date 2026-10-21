import 'package:equatable/equatable.dart';

/// Arah paket pelacakan live: Kiriman Saya (outgoing) vs Paket Masuk (incoming)
enum OrderDirection {
  outgoing('Kiriman Saya'),
  incoming('Paket Masuk');

  final String label;
  const OrderDirection(this.label);
}

/// Status filter pesanan pelacakan live
enum OrderFilterStatus {
  all('Semua'),
  waitingPickup('Menunggu Pickup'),
  inDelivery('Sedang Diantar'),
  completed('Selesai');

  final String label;
  const OrderFilterStatus(this.label);
}

/// Catatan kronologis riwayat perjalanan paket dari tabel t_shipment_tracking
class LiveTrackTimelineStep extends Equatable {
  final String id;
  final int statusId;
  final String statusCode;
  final String statusName;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String notes;
  final DateTime createdAt;
  final bool isCurrent;

  const LiveTrackTimelineStep({
    required this.id,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.notes,
    required this.createdAt,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props => [
        id,
        statusId,
        statusCode,
        statusName,
        locationName,
        latitude,
        longitude,
        notes,
        createdAt,
        isCurrent,
      ];
}

/// Entity data pelacakan live kurir & pengiriman pesanan khusus Customer
class LiveTrackShipment extends Equatable {
  final String id;
  final String trackingNumber;
  final String barcodeValue;
  final int customerId;
  final int serviceTypeId;
  final String serviceTypeName;
  final String serviceTypeCode;
  final int statusId;
  final String statusCode;
  final String statusName;
  final String statusDescription;
  final OrderDirection direction;
  final OrderFilterStatus filterStatus;

  // Data Pengirim
  final String senderName;
  final String senderPhone;
  final String senderAddress;
  final String senderCity;
  final double? senderLatitude;
  final double? senderLongitude;

  // Data Penerima / Titik Tujuan
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String receiverCity;
  final String? receiverPostalCode;
  final double? receiverLatitude;
  final double? receiverLongitude;

  // Data Kurir & Posisi Terkini dari t_shipment_locations / t_shipment_tracking
  final String? courierName;
  final String? courierPhone;
  final String? courierVehicle;
  final double? courierLatitude;
  final double? courierLongitude;
  final DateTime? courierLocationUpdatedAt;
  final double? courierHeading;
  final double? courierSpeed;

  // Estimasi & Jarak (hanya jika data valid tersedia)
  final int? etaMinutes;
  final double? distanceKm;
  final DateTime? estimatedArrival;

  // Detail Tambahan Pengiriman
  final int totalPrice;
  final int totalWeightGram;
  final String? shippingNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LiveTrackTimelineStep> timeline;

  const LiveTrackShipment({
    required this.id,
    required this.trackingNumber,
    required this.barcodeValue,
    required this.customerId,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.serviceTypeCode,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
    required this.statusDescription,
    required this.direction,
    required this.filterStatus,
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
    this.receiverPostalCode,
    this.receiverLatitude,
    this.receiverLongitude,
    this.courierName,
    this.courierPhone,
    this.courierVehicle,
    this.courierLatitude,
    this.courierLongitude,
    this.courierLocationUpdatedAt,
    this.courierHeading,
    this.courierSpeed,
    this.etaMinutes,
    this.distanceKm,
    this.estimatedArrival,
    required this.totalPrice,
    required this.totalWeightGram,
    this.shippingNotes,
    required this.createdAt,
    required this.updatedAt,
    this.timeline = const [],
  });

  /// Indikator apakah posisi GPS kurir saat ini tersedia dan aktif
  bool get isCourierGpsAvailable =>
      courierLatitude != null &&
      courierLongitude != null &&
      courierLatitude != 0.0 &&
      courierLongitude != 0.0;

  /// Indikator apakah koordinat titik tujuan penerima tersedia
  bool get hasDestinationCoordinates =>
      receiverLatitude != null &&
      receiverLongitude != null &&
      receiverLatitude != 0.0 &&
      receiverLongitude != 0.0;

  /// Indikator apakah pengiriman sedang dalam proses pengantaran aktif
  bool get isActive =>
      filterStatus == OrderFilterStatus.waitingPickup ||
      filterStatus == OrderFilterStatus.inDelivery;

  /// Indikator apakah paket sudah sampai / selesai
  bool get isCompleted =>
      filterStatus == OrderFilterStatus.completed ||
      statusCode.toUpperCase() == 'DELIVERED';

  /// Deskripsi ramah pengguna mengenai waktu pembaruan lokasi kurir terakhir
  String get locationFreshnessDescription {
    if (courierLocationUpdatedAt == null) {
      return 'Belum ada data lokasi';
    }
    final diff = DateTime.now().difference(courierLocationUpdatedAt!);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  /// Indikator apakah data lokasi kurir masih segar (< 15 menit)
  bool get isLocationFresh {
    if (courierLocationUpdatedAt == null) return false;
    final diff = DateTime.now().difference(courierLocationUpdatedAt!);
    return diff.inMinutes <= 15;
  }

  LiveTrackShipment copyWith({
    String? id,
    String? trackingNumber,
    String? barcodeValue,
    int? customerId,
    int? serviceTypeId,
    String? serviceTypeName,
    String? serviceTypeCode,
    int? statusId,
    String? statusCode,
    String? statusName,
    String? statusDescription,
    OrderDirection? direction,
    OrderFilterStatus? filterStatus,
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
    String? receiverPostalCode,
    double? receiverLatitude,
    double? receiverLongitude,
    String? courierName,
    String? courierPhone,
    String? courierVehicle,
    double? courierLatitude,
    double? courierLongitude,
    DateTime? courierLocationUpdatedAt,
    double? courierHeading,
    double? courierSpeed,
    int? etaMinutes,
    double? distanceKm,
    DateTime? estimatedArrival,
    int? totalPrice,
    int? totalWeightGram,
    String? shippingNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LiveTrackTimelineStep>? timeline,
  }) {
    return LiveTrackShipment(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      customerId: customerId ?? this.customerId,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      serviceTypeName: serviceTypeName ?? this.serviceTypeName,
      serviceTypeCode: serviceTypeCode ?? this.serviceTypeCode,
      statusId: statusId ?? this.statusId,
      statusCode: statusCode ?? this.statusCode,
      statusName: statusName ?? this.statusName,
      statusDescription: statusDescription ?? this.statusDescription,
      direction: direction ?? this.direction,
      filterStatus: filterStatus ?? this.filterStatus,
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
      receiverPostalCode: receiverPostalCode ?? this.receiverPostalCode,
      receiverLatitude: receiverLatitude ?? this.receiverLatitude,
      receiverLongitude: receiverLongitude ?? this.receiverLongitude,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      courierVehicle: courierVehicle ?? this.courierVehicle,
      courierLatitude: courierLatitude ?? this.courierLatitude,
      courierLongitude: courierLongitude ?? this.courierLongitude,
      courierLocationUpdatedAt:
          courierLocationUpdatedAt ?? this.courierLocationUpdatedAt,
      courierHeading: courierHeading ?? this.courierHeading,
      courierSpeed: courierSpeed ?? this.courierSpeed,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      totalPrice: totalPrice ?? this.totalPrice,
      totalWeightGram: totalWeightGram ?? this.totalWeightGram,
      shippingNotes: shippingNotes ?? this.shippingNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeline: timeline ?? this.timeline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        trackingNumber,
        barcodeValue,
        customerId,
        serviceTypeId,
        serviceTypeName,
        statusId,
        statusCode,
        statusName,
        direction,
        filterStatus,
        senderName,
        receiverName,
        receiverLatitude,
        receiverLongitude,
        courierName,
        courierPhone,
        courierVehicle,
        courierLatitude,
        courierLongitude,
        courierLocationUpdatedAt,
        courierHeading,
        courierSpeed,
        etaMinutes,
        distanceKm,
        estimatedArrival,
        totalPrice,
        updatedAt,
        timeline,
      ];
}
