import '../../domain/entities/shipment.dart';

class CourierModel extends Courier {
  const CourierModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.photoUrl,
    required super.vehicleType,
    required super.vehiclePlate,
    super.rating = 4.9,
    required super.latitude,
    required super.longitude,
  });

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    return CourierModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      vehiclePlate: json['vehiclePlate'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory CourierModel.fromEntity(Courier entity) {
    return CourierModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      photoUrl: entity.photoUrl,
      vehicleType: entity.vehicleType,
      vehiclePlate: entity.vehiclePlate,
      rating: entity.rating,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
