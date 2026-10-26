import 'package:equatable/equatable.dart';

/// Entitas bisnis representasi tugas aktif yang sedang dijalankan kurir untuk pelacakan GPS
class CourierTrackingTask extends Equatable {
  final String taskId;
  final String shipmentId;
  final String courierId;
  final String trackingNumber;
  final String barcodeValue;
  final bool isPickup;
  final int statusId;
  final String statusCode;
  final String statusName;
  final String senderName;
  final String senderPhone;
  final String senderAddress;
  final String senderCity;
  final double? senderLatitude;
  final double? senderLongitude;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String receiverCity;
  final double? receiverLatitude;
  final double? receiverLongitude;
  final String serviceTypeName;
  final String serviceTypeCode;
  final DateTime assignedAt;
  final String? notes;

  const CourierTrackingTask({
    required this.taskId,
    required this.shipmentId,
    required this.courierId,
    required this.trackingNumber,
    required this.barcodeValue,
    required this.isPickup,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
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
    required this.serviceTypeName,
    required this.serviceTypeCode,
    required this.assignedAt,
    this.notes,
  });

  /// True jika tugas adalah pengantaran paket
  bool get isDelivery => !isPickup;

  /// Label jenis tugas (Pengambilan atau Pengantaran)
  String get taskTypeLabel => isPickup ? 'Pengambilan' : 'Pengantaran';

  /// Nama pihak tujuan aktivitas kurir
  String get targetPersonName => isPickup ? senderName : receiverName;

  /// Nomor telepon pihak tujuan
  String get targetPersonPhone => isPickup ? senderPhone : receiverPhone;

  /// Alamat tujuan aktivitas kurir
  String get targetAddress => isPickup ? senderAddress : receiverAddress;

  /// Kota tujuan aktivitas kurir
  String get targetCity => isPickup ? senderCity : receiverCity;

  /// Koordinat latitude tujuan
  double? get targetLatitude => isPickup ? senderLatitude : receiverLatitude;

  /// Koordinat longitude tujuan
  double? get targetLongitude => isPickup ? senderLongitude : receiverLongitude;

  /// True jika koordinat tujuan tersedia dan valid
  bool get hasTargetCoordinates =>
      targetLatitude != null &&
      targetLongitude != null &&
      targetLatitude != 0.0 &&
      targetLongitude != 0.0;

  @override
  List<Object?> get props => [
        taskId,
        shipmentId,
        courierId,
        trackingNumber,
        isPickup,
        statusId,
        statusCode,
        assignedAt,
      ];
}
