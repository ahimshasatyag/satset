import 'package:equatable/equatable.dart';

/// Arah paket: Kiriman Saya (dikirim keluar) vs Paket Masuk (menuju ke pengguna)
enum OrderDirection {
  outgoing('Kiriman Saya'),
  incoming('Paket Masuk');

  final String label;
  const OrderDirection(this.label);
}

/// Status filter pesanan pengiriman
enum OrderFilterStatus {
  all('Semua'),
  waitingPickup('Menunggu Penjemputan'),
  inDelivery('Sedang Diantar Kurir'),
  completed('Pesanan Selesai');

  final String label;
  const OrderFilterStatus(this.label);
}

/// Entity data pesanan pengiriman
class OrderShipment extends Equatable {
  final String id;
  final String trackingNumber;
  final String itemName;
  final String itemCategory;
  final String serviceType;
  final OrderDirection direction;
  final OrderFilterStatus filterStatus;
  final String senderName;
  final String receiverName;
  final String originCity;
  final String destinationCity;
  final String statusDescription;
  final String courierName;
  final String courierPhone;
  final String courierVehicle;
  final int etaMinutes;
  final double distanceKm;
  final int price;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderShipment({
    required this.id,
    required this.trackingNumber,
    required this.itemName,
    required this.itemCategory,
    required this.serviceType,
    required this.direction,
    required this.filterStatus,
    required this.senderName,
    required this.receiverName,
    required this.originCity,
    required this.destinationCity,
    required this.statusDescription,
    required this.courierName,
    required this.courierPhone,
    required this.courierVehicle,
    required this.etaMinutes,
    required this.distanceKm,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      filterStatus == OrderFilterStatus.waitingPickup ||
      filterStatus == OrderFilterStatus.inDelivery;

  OrderShipment copyWith({
    String? id,
    String? trackingNumber,
    String? itemName,
    String? itemCategory,
    String? serviceType,
    OrderDirection? direction,
    OrderFilterStatus? filterStatus,
    String? senderName,
    String? receiverName,
    String? originCity,
    String? destinationCity,
    String? statusDescription,
    String? courierName,
    String? courierPhone,
    String? courierVehicle,
    int? etaMinutes,
    double? distanceKm,
    int? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderShipment(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      serviceType: serviceType ?? this.serviceType,
      direction: direction ?? this.direction,
      filterStatus: filterStatus ?? this.filterStatus,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      statusDescription: statusDescription ?? this.statusDescription,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      courierVehicle: courierVehicle ?? this.courierVehicle,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        trackingNumber,
        itemName,
        direction,
        filterStatus,
        senderName,
        receiverName,
        courierName,
        courierVehicle,
        etaMinutes,
        updatedAt,
      ];
}
