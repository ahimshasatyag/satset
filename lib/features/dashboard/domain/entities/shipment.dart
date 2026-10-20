import 'package:equatable/equatable.dart';

/// Titik koordinat dan lokasi geografis dalam sistem pengiriman SatSet
class LocationPoint extends Equatable {
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;

  const LocationPoint({
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  static const empty = LocationPoint(
    name: '',
    address: '',
    city: '',
    latitude: 0.0,
    longitude: 0.0,
  );

  @override
  List<Object?> get props => [name, address, city, latitude, longitude];
}

/// Data informasi kurir pengantar paket
class Courier extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String photoUrl;
  final String vehicleType;
  final String vehiclePlate;
  final double rating;
  final double latitude;
  final double longitude;

  const Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.vehicleType,
    required this.vehiclePlate,
    this.rating = 4.9,
    required this.latitude,
    required this.longitude,
  });

  Courier copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoUrl,
    String? vehicleType,
    String? vehiclePlate,
    double? rating,
    double? latitude,
    double? longitude,
  }) {
    return Courier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      rating: rating ?? this.rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        photoUrl,
        vehicleType,
        vehiclePlate,
        rating,
        latitude,
        longitude,
      ];
}

/// Tahapan status pengiriman
enum ShipmentStatus {
  pending,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case ShipmentStatus.pending:
        return 'Menunggu Penjemputan';
      case ShipmentStatus.pickedUp:
        return 'Paket Dijemput';
      case ShipmentStatus.inTransit:
        return 'Dalam Perjalanan';
      case ShipmentStatus.outForDelivery:
        return 'Kurir Menuju Lokasi';
      case ShipmentStatus.delivered:
        return 'Terkirim';
      case ShipmentStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  int get stepIndex {
    switch (this) {
      case ShipmentStatus.pending:
        return 0;
      case ShipmentStatus.pickedUp:
        return 1;
      case ShipmentStatus.inTransit:
        return 2;
      case ShipmentStatus.outForDelivery:
        return 3;
      case ShipmentStatus.delivered:
        return 4;
      case ShipmentStatus.cancelled:
        return -1;
    }
  }
}

/// Riwayat log pergerakan / jejak status paket
class ShipmentTimelineStep extends Equatable {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final bool isCurrent;

  const ShipmentTimelineStep({
    required this.title,
    required this.description,
    required this.timestamp,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props => [title, description, timestamp, isCompleted, isCurrent];
}

/// Entity bisnis utama untuk Pengiriman SatSet
class Shipment extends Equatable {
  final String id;
  final String trackingNumber;
  final String itemName;
  final String itemCategory;
  final String serviceType; // e.g. "SATSET Instant", "SATSET Sameday"
  final ShipmentStatus status;
  final LocationPoint origin;
  final LocationPoint destination;
  final Courier? courier;
  final LocationPoint courierPosition;
  final int etaMinutes;
  final double distanceKm;
  final DateTime updatedAt;
  final List<ShipmentTimelineStep> timeline;

  const Shipment({
    required this.id,
    required this.trackingNumber,
    required this.itemName,
    required this.itemCategory,
    required this.serviceType,
    required this.status,
    required this.origin,
    required this.destination,
    this.courier,
    required this.courierPosition,
    required this.etaMinutes,
    required this.distanceKm,
    required this.updatedAt,
    this.timeline = const [],
  });

  /// Persentase progres pengiriman (0.0 s/d 1.0)
  double get progressPercentage {
    switch (status) {
      case ShipmentStatus.pending:
        return 0.1;
      case ShipmentStatus.pickedUp:
        return 0.35;
      case ShipmentStatus.inTransit:
        return 0.65;
      case ShipmentStatus.outForDelivery:
        return 0.90;
      case ShipmentStatus.delivered:
        return 1.0;
      case ShipmentStatus.cancelled:
        return 0.0;
    }
  }

  String get etaDisplay {
    if (status == ShipmentStatus.delivered) return 'Tiba di tujuan';
    if (etaMinutes <= 0) return 'Tiba sebentar lagi';
    if (etaMinutes < 60) return '$etaMinutes Menit';
    final hours = etaMinutes ~/ 60;
    final mins = etaMinutes % 60;
    return mins > 0 ? '$hours Jam $mins Menit' : '$hours Jam';
  }

  Shipment copyWith({
    String? id,
    String? trackingNumber,
    String? itemName,
    String? itemCategory,
    String? serviceType,
    ShipmentStatus? status,
    LocationPoint? origin,
    LocationPoint? destination,
    Courier? courier,
    LocationPoint? courierPosition,
    int? etaMinutes,
    double? distanceKm,
    DateTime? updatedAt,
    List<ShipmentTimelineStep>? timeline,
  }) {
    return Shipment(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      courier: courier ?? this.courier,
      courierPosition: courierPosition ?? this.courierPosition,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      updatedAt: updatedAt ?? this.updatedAt,
      timeline: timeline ?? this.timeline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        trackingNumber,
        itemName,
        itemCategory,
        serviceType,
        status,
        origin,
        destination,
        courier,
        courierPosition,
        etaMinutes,
        distanceKm,
        updatedAt,
        timeline,
      ];
}
