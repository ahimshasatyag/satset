import '../../domain/entities/order_shipment.dart';

class OrderShipmentModel extends OrderShipment {
  const OrderShipmentModel({
    required super.id,
    required super.trackingNumber,
    required super.itemName,
    required super.itemCategory,
    required super.serviceType,
    required super.direction,
    required super.filterStatus,
    required super.senderName,
    required super.receiverName,
    required super.originCity,
    required super.destinationCity,
    required super.statusDescription,
    required super.courierName,
    required super.courierPhone,
    required super.courierVehicle,
    required super.etaMinutes,
    required super.distanceKm,
    required super.price,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderShipmentModel.fromJson(Map<String, dynamic> json) {
    final dir = (json['direction'] as String? ?? 'outgoing') == 'incoming'
        ? OrderDirection.incoming
        : OrderDirection.outgoing;

    OrderFilterStatus status;
    switch ((json['filterStatus'] as String? ?? '').toLowerCase()) {
      case 'waitingpickup':
      case 'waiting_pickup':
        status = OrderFilterStatus.waitingPickup;
        break;
      case 'indelivery':
      case 'in_delivery':
        status = OrderFilterStatus.inDelivery;
        break;
      case 'completed':
        status = OrderFilterStatus.completed;
        break;
      default:
        status = OrderFilterStatus.all;
    }

    return OrderShipmentModel(
      id: json['id'] as String? ?? '',
      trackingNumber: json['trackingNumber'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      itemCategory: json['itemCategory'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? 'SATSET Instant',
      direction: dir,
      filterStatus: status,
      senderName: json['senderName'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? '',
      originCity: json['originCity'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      statusDescription: json['statusDescription'] as String? ?? '',
      courierName: json['courierName'] as String? ?? '',
      courierPhone: json['courierPhone'] as String? ?? '',
      courierVehicle: json['courierVehicle'] as String? ?? '',
      etaMinutes: json['etaMinutes'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      price: json['price'] as int? ?? 15000,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory OrderShipmentModel.fromEntity(OrderShipment entity) {
    return OrderShipmentModel(
      id: entity.id,
      trackingNumber: entity.trackingNumber,
      itemName: entity.itemName,
      itemCategory: entity.itemCategory,
      serviceType: entity.serviceType,
      direction: entity.direction,
      filterStatus: entity.filterStatus,
      senderName: entity.senderName,
      receiverName: entity.receiverName,
      originCity: entity.originCity,
      destinationCity: entity.destinationCity,
      statusDescription: entity.statusDescription,
      courierName: entity.courierName,
      courierPhone: entity.courierPhone,
      courierVehicle: entity.courierVehicle,
      etaMinutes: entity.etaMinutes,
      distanceKm: entity.distanceKm,
      price: entity.price,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'serviceType': serviceType,
      'direction': direction.name,
      'filterStatus': filterStatus.name,
      'senderName': senderName,
      'receiverName': receiverName,
      'originCity': originCity,
      'destinationCity': destinationCity,
      'statusDescription': statusDescription,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'courierVehicle': courierVehicle,
      'etaMinutes': etaMinutes,
      'distanceKm': distanceKm,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
