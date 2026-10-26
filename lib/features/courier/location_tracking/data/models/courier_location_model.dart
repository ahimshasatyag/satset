import 'package:geolocator/geolocator.dart';
import '../../domain/entities/courier_location.dart';

/// Model implementasi [CourierLocation] dengan konversi Geolocator dan Supabase
class CourierLocationModel extends CourierLocation {
  const CourierLocationModel({
    required super.latitude,
    required super.longitude,
    super.accuracy,
    super.altitude,
    super.speed,
    super.heading,
    required super.timestamp,
  });

  /// Factory untuk membuat model dari objek [Position] Geolocator perangkat
  factory CourierLocationModel.fromPosition(Position position) {
    return CourierLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
    );
  }

  /// Factory dari catatan basis data [t_shipment_locations]
  factory CourierLocationModel.fromDatabase(Map<String, dynamic> map) {
    final recordedAt = map['recorded_at'] != null
        ? DateTime.tryParse(map['recorded_at'].toString()) ?? DateTime.now()
        : (map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now());

    return CourierLocationModel(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy_m'] as num?)?.toDouble() ??
          (map['accuracy'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed_mps'] as num?)?.toDouble() ??
          (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      timestamp: recordedAt,
    );
  }

  factory CourierLocationModel.fromJson(Map<String, dynamic> json) {
    return CourierLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Format data yang siap dimasukkan ke tabel [t_shipment_locations] di Supabase
  Map<String, dynamic> toDatabaseInsert({
    required String shipmentId,
    required String courierId,
  }) {
    final parsedShipmentId = int.tryParse(shipmentId) ?? shipmentId;
    final parsedCourierId = int.tryParse(courierId) ?? courierId;

    return {
      'shipment_id': parsedShipmentId,
      'courier_id': parsedCourierId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_mps': speed ?? 0.0,
      'heading': heading ?? 0.0,
      'accuracy_m': accuracy ?? 0.0,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
