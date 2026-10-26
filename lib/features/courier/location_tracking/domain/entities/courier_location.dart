import 'package:equatable/equatable.dart';

/// Entitas bisnis koordinat posisi GPS kurir
class CourierLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  const CourierLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  /// Memeriksa apakah koordinat valid (bukan 0.0 atau tak tentu)
  bool get isValid =>
      latitude != 0.0 &&
      longitude != 0.0 &&
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;

  /// Deskripsi akurasi yang mudah dipahami
  String get accuracyLabel {
    if (accuracy == null) return 'Tidak diketahui';
    if (accuracy! <= 10) return 'Tinggi (±${accuracy!.toStringAsFixed(0)}m)';
    if (accuracy! <= 30) return 'Sedang (±${accuracy!.toStringAsFixed(0)}m)';
    return 'Rendah (±${accuracy!.toStringAsFixed(0)}m)';
  }

  /// Kecepatan dalam km/jam
  double get speedKmh => (speed ?? 0.0) * 3.6;

  CourierLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
  }) {
    return CourierLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        heading,
        timestamp,
      ];
}
