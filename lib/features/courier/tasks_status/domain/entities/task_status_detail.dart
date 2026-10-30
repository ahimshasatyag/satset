import 'package:equatable/equatable.dart';
import 'status_transition_option.dart';

/// Entity komprehensif status dan informasi detail tugas kurir
class TaskStatusDetail extends Equatable {
  final String shipmentId;
  final String assignmentId;
  final String trackingNumber;
  final String? barcodeValue;
  final String senderName;
  final String senderPhone;
  final String senderAddress;
  final String senderCity;
  final String? senderPostalCode;
  final double? senderLatitude;
  final double? senderLongitude;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String receiverCity;
  final String? receiverPostalCode;
  final double? receiverLatitude;
  final double? receiverLongitude;
  final String? serviceTypeName;
  final String? serviceTypeCode;
  final int? totalWeightGram;
  final double? shippingCost;
  final String? paymentMethod;
  final String paymentStatus;
  final String? shippingNotes;
  final int currentStatusId;
  final String currentStatusCode;
  final String currentStatusName;
  final bool isFinalStatus;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? estimatedArrival;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaskStatusDetail({
    required this.shipmentId,
    required this.assignmentId,
    required this.trackingNumber,
    this.barcodeValue,
    required this.senderName,
    required this.senderPhone,
    required this.senderAddress,
    required this.senderCity,
    this.senderPostalCode,
    this.senderLatitude,
    this.senderLongitude,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.receiverCity,
    this.receiverPostalCode,
    this.receiverLatitude,
    this.receiverLongitude,
    this.serviceTypeName,
    this.serviceTypeCode,
    this.totalWeightGram,
    this.shippingCost,
    this.paymentMethod,
    this.paymentStatus = 'PENDING',
    this.shippingNotes,
    required this.currentStatusId,
    required this.currentStatusCode,
    required this.currentStatusName,
    this.isFinalStatus = false,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.estimatedArrival,
    required this.createdAt,
    this.updatedAt,
  });

  /// True jika tugas tergolong tahapan penjemputan (Pickup)
  bool get isPickupTask {
    final code = currentStatusCode.toUpperCase();
    return code == 'PENDING' || code == 'CONFIRMED' || code == 'PICKUP_SCHEDULED';
  }

  /// True jika tugas tergolong tahapan pengantaran (Delivery)
  bool get isDeliveryTask => !isPickupTask;

  /// Label jenis tugas operasional
  String get taskTypeLabel => isPickupTask ? 'Tugas Pickup' : 'Tugas Pengantaran';

  /// Alamat lengkap pengirim
  String get fullSenderAddress {
    if (senderCity.isNotEmpty) {
      return '$senderAddress, $senderCity';
    }
    return senderAddress;
  }

  /// Alamat lengkap penerima
  String get fullReceiverAddress {
    if (receiverCity.isNotEmpty) {
      return '$receiverAddress, $receiverCity';
    }
    return receiverAddress;
  }

  /// True jika pembayaran sudah lunas / selesai / COD
  bool get isPaid =>
      paymentStatus.toUpperCase() == 'PAID' ||
      paymentStatus.toUpperCase() == 'SETTLED' ||
      (paymentMethod?.toUpperCase() == 'COD');

  /// True jika paket masih menunggu pembayaran dari pelanggan
  bool get isWaitingPayment => !isPaid;

  /// True jika status sudah final dan tidak dapat diperbarui lagi
  bool get isCompleted =>
      isFinalStatus ||
      currentStatusCode.toUpperCase() == 'DELIVERED' ||
      currentStatusCode.toUpperCase() == 'CANCELLED' ||
      currentStatusCode.toUpperCase() == 'RETURNED';

  /// Daftar transisi status berikutnya yang sah sesuai status terkini dan aturan operasional
  List<StatusTransitionOption> get validNextTransitions {
    // Jika masih menunggu pembayaran atau sudah selesai, kunci transisi berikutnya!
    if (isCompleted || isWaitingPayment) {
      return const [];
    }

    switch (currentStatusCode.toUpperCase()) {
      case 'PENDING':
      case 'CONFIRMED':
        return [
          StatusTransitionOption.forCode('PICKUP_SCHEDULED'),
        ];

      case 'PICKUP_SCHEDULED':
        return [
          StatusTransitionOption.forCode('PICKED_UP'),
        ];

      case 'PICKED_UP':
        return [
          StatusTransitionOption.forCode('IN_TRANSIT'),
        ];

      case 'IN_TRANSIT':
        return [
          StatusTransitionOption.forCode('AT_SORTING_CENTER'),
          StatusTransitionOption.forCode('OUT_FOR_DELIVERY'),
        ];

      case 'AT_SORTING_CENTER':
        return [
          StatusTransitionOption.forCode('OUT_FOR_DELIVERY'),
        ];

      case 'OUT_FOR_DELIVERY':
        return [
          StatusTransitionOption.forCode('DELIVERED'),
          StatusTransitionOption.forCode('FAILED_DELIVERY'),
        ];

      case 'FAILED_DELIVERY':
        return [
          StatusTransitionOption.forCode('OUT_FOR_DELIVERY'),
        ];

      default:
        return const [];
    }
  }

  @override
  List<Object?> get props => [
        shipmentId,
        assignmentId,
        trackingNumber,
        barcodeValue,
        senderName,
        senderPhone,
        senderAddress,
        senderCity,
        senderPostalCode,
        senderLatitude,
        senderLongitude,
        receiverName,
        receiverPhone,
        receiverAddress,
        receiverCity,
        receiverPostalCode,
        receiverLatitude,
        receiverLongitude,
        serviceTypeName,
        serviceTypeCode,
        totalWeightGram,
        shippingCost,
        paymentMethod,
        paymentStatus,
        shippingNotes,
        currentStatusId,
        currentStatusCode,
        currentStatusName,
        isFinalStatus,
        assignedAt,
        pickedUpAt,
        deliveredAt,
        estimatedArrival,
        createdAt,
        updatedAt,
      ];
}
