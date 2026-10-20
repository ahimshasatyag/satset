import '../../domain/entities/shipment.dart';
import 'courier_model.dart';
import 'location_point_model.dart';

class ShipmentTimelineStepModel extends ShipmentTimelineStep {
  const ShipmentTimelineStepModel({
    required super.title,
    required super.description,
    required super.timestamp,
    super.isCompleted = false,
    super.isCurrent = false,
  });

  factory ShipmentTimelineStepModel.fromJson(Map<String, dynamic> json) {
    return ShipmentTimelineStepModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
      'isCurrent': isCurrent,
    };
  }

  factory ShipmentTimelineStepModel.fromEntity(ShipmentTimelineStep entity) {
    return ShipmentTimelineStepModel(
      title: entity.title,
      description: entity.description,
      timestamp: entity.timestamp,
      isCompleted: entity.isCompleted,
      isCurrent: entity.isCurrent,
    );
  }
}

class ShipmentModel extends Shipment {
  const ShipmentModel({
    required super.id,
    required super.trackingNumber,
    required super.itemName,
    required super.itemCategory,
    required super.serviceType,
    required super.status,
    required super.origin,
    required super.destination,
    super.courier,
    required super.courierPosition,
    required super.etaMinutes,
    required super.distanceKm,
    required super.updatedAt,
    super.timeline = const [],
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    ShipmentStatus parsedStatus;
    final statusString = (json['status'] as String? ?? '').toLowerCase();
    switch (statusString) {
      case 'pickedup':
      case 'picked_up':
        parsedStatus = ShipmentStatus.pickedUp;
        break;
      case 'intransit':
      case 'in_transit':
        parsedStatus = ShipmentStatus.inTransit;
        break;
      case 'outfordelivery':
      case 'out_for_delivery':
        parsedStatus = ShipmentStatus.outForDelivery;
        break;
      case 'delivered':
        parsedStatus = ShipmentStatus.delivered;
        break;
      case 'cancelled':
        parsedStatus = ShipmentStatus.cancelled;
        break;
      default:
        parsedStatus = ShipmentStatus.pending;
    }

    return ShipmentModel(
      id: json['id'] as String? ?? '',
      trackingNumber: json['trackingNumber'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      itemCategory: json['itemCategory'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? 'SATSET Instant',
      status: parsedStatus,
      origin: json['origin'] != null
          ? LocationPointModel.fromJson(json['origin'] as Map<String, dynamic>)
          : LocationPoint.empty,
      destination: json['destination'] != null
          ? LocationPointModel.fromJson(
              json['destination'] as Map<String, dynamic>)
          : LocationPoint.empty,
      courier: json['courier'] != null
          ? CourierModel.fromJson(json['courier'] as Map<String, dynamic>)
          : null,
      courierPosition: json['courierPosition'] != null
          ? LocationPointModel.fromJson(
              json['courierPosition'] as Map<String, dynamic>)
          : LocationPoint.empty,
      etaMinutes: json['etaMinutes'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((item) => ShipmentTimelineStepModel.fromJson(
                  item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'serviceType': serviceType,
      'status': status.name,
      'origin': (origin is LocationPointModel)
          ? (origin as LocationPointModel).toJson()
          : LocationPointModel.fromEntity(origin).toJson(),
      'destination': (destination is LocationPointModel)
          ? (destination as LocationPointModel).toJson()
          : LocationPointModel.fromEntity(destination).toJson(),
      'courier': courier != null
          ? ((courier is CourierModel)
              ? (courier as CourierModel).toJson()
              : CourierModel.fromEntity(courier!).toJson())
          : null,
      'courierPosition': (courierPosition is LocationPointModel)
          ? (courierPosition as LocationPointModel).toJson()
          : LocationPointModel.fromEntity(courierPosition).toJson(),
      'etaMinutes': etaMinutes,
      'distanceKm': distanceKm,
      'updatedAt': updatedAt.toIso8601String(),
      'timeline': timeline
          .map((item) => (item is ShipmentTimelineStepModel)
              ? item.toJson()
              : ShipmentTimelineStepModel.fromEntity(item).toJson())
          .toList(),
    };
  }

  factory ShipmentModel.fromEntity(Shipment entity) {
    return ShipmentModel(
      id: entity.id,
      trackingNumber: entity.trackingNumber,
      itemName: entity.itemName,
      itemCategory: entity.itemCategory,
      serviceType: entity.serviceType,
      status: entity.status,
      origin: entity.origin,
      destination: entity.destination,
      courier: entity.courier,
      courierPosition: entity.courierPosition,
      etaMinutes: entity.etaMinutes,
      distanceKm: entity.distanceKm,
      updatedAt: entity.updatedAt,
      timeline: entity.timeline,
    );
  }
}
