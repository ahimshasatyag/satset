import '../../domain/entities/shipment.dart';

class LocationPointModel extends LocationPoint {
  const LocationPointModel({
    required super.name,
    required super.address,
    required super.city,
    required super.latitude,
    required super.longitude,
  });

  factory LocationPointModel.fromJson(Map<String, dynamic> json) {
    return LocationPointModel(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationPointModel.fromEntity(LocationPoint entity) {
    return LocationPointModel(
      name: entity.name,
      address: entity.address,
      city: entity.city,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
