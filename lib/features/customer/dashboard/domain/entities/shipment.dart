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

  static const empty = Courier(
    id: '',
    name: 'Kurir SatSet',
    phone: '',
    photoUrl: '',
    vehicleType: 'Motor',
    vehiclePlate: '',
    latitude: 0.0,
    longitude: 0.0,
  );

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

/// Riwayat log pergerakan / jejak status paket dari t_shipment_tracking
class ShipmentTimelineStep extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final bool isCompleted;
  final bool isCurrent;

  const ShipmentTimelineStep({
    this.id = '',
    required this.title,
    required this.description,
    this.location,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        latitude,
        longitude,
        timestamp,
        isCompleted,
        isCurrent,
      ];
}

/// Status pengiriman untuk representasi visual
enum ShipmentStatus {
  pending('Menunggu Konfirmasi', 0),
  pickedUp('Paket Dijemput', 0),
  inTransit('Dalam Perjalanan', 1),
  outForDelivery('Sedang Diantar', 2),
  delivered('Paket Diterima', 3),
  cancelled('Dibatalkan', 0);

  final String label;
  final int stepIndex;
  const ShipmentStatus(this.label, this.stepIndex);
}

/// Ringkasan jumlah pengiriman milik pelanggan berdasarkan status Supabase m_shipment_statuses
class ShipmentStatusSummary extends Equatable {
  final int waitingConfirmation; // PENDING (1), CONFIRMED (2)
  final int inProcess; // PICKUP_SCHEDULED (3), PICKED_UP (4), AT_SORTING_CENTER (6)
  final int inTransit; // IN_TRANSIT (5), OUT_FOR_DELIVERY (7)
  final int delivered; // DELIVERED (8)
  final int total;

  const ShipmentStatusSummary({
    int waitingConfirmation = 0,
    int inProcess = 0,
    int inTransit = 0,
    int delivered = 0,
    int total = 0,
    int? waitingConfirmationCount,
    int? inProcessCount,
    int? inTransitCount,
    int? deliveredCount,
    int? totalShipments,
  })  : waitingConfirmation = waitingConfirmationCount ?? waitingConfirmation,
        inProcess = inProcessCount ?? inProcess,
        inTransit = inTransitCount ?? inTransit,
        delivered = deliveredCount ?? delivered,
        total = totalShipments ?? total;

  int get waitingConfirmationCount => waitingConfirmation;
  int get inProcessCount => inProcess;
  int get inTransitCount => inTransit;
  int get deliveredCount => delivered;
  int get totalShipments =>
      total > 0 ? total : (waitingConfirmation + inProcess + inTransit + delivered);

  static const empty = ShipmentStatusSummary();

  @override
  List<Object?> get props => [
        waitingConfirmation,
        inProcess,
        inTransit,
        delivered,
        total,
      ];
}

/// Entity bisnis utama untuk Pengiriman SatSet (t_shipments)
class Shipment extends Equatable {
  final String id;
  final String nomorResi;
  final String barcodeValue;
  final int customerId;
  final int serviceTypeId;
  final String serviceName;
  final String serviceCode;
  final int? estimasiHariMin;
  final int? estimasiHariMax;
  final int statusId;
  final String statusCode;
  final String statusName;
  final String pengirimNama;
  final String pengirimNoHp;
  final String pengirimAlamat;
  final String pengirimKota;
  final double? pengirimLatitude;
  final double? pengirimLongitude;
  final String penerimaNama;
  final String penerimaNoHp;
  final String penerimaAlamat;
  final String penerimaKota;
  final double? penerimaLatitude;
  final double? penerimaLongitude;
  final int totalBeratGram;
  final int totalBarang;
  final double nilaiBarang;
  final double biayaPengiriman;
  final double biayaAsuransi;
  final double totalBiaya;
  final String metodePembayaran;
  final String? catatanPengiriman;
  final DateTime? estimasiTiba;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShipmentTimelineStep> timeline;
  final Courier? courier;
  final LocationPoint? courierPosition;

  const Shipment({
    required this.id,
    required this.nomorResi,
    required this.barcodeValue,
    required this.customerId,
    required this.serviceTypeId,
    required this.serviceName,
    this.serviceCode = 'REG',
    this.estimasiHariMin,
    this.estimasiHariMax,
    required this.statusId,
    required this.statusCode,
    required this.statusName,
    required this.pengirimNama,
    required this.pengirimNoHp,
    required this.pengirimAlamat,
    this.pengirimKota = 'Jakarta',
    this.pengirimLatitude,
    this.pengirimLongitude,
    required this.penerimaNama,
    required this.penerimaNoHp,
    required this.penerimaAlamat,
    this.penerimaKota = 'Jakarta',
    this.penerimaLatitude,
    this.penerimaLongitude,
    this.totalBeratGram = 0,
    this.totalBarang = 1,
    this.nilaiBarang = 0.0,
    this.biayaPengiriman = 0.0,
    this.biayaAsuransi = 0.0,
    this.totalBiaya = 0.0,
    this.metodePembayaran = 'TRANSFER',
    this.catatanPengiriman,
    this.estimasiTiba,
    this.pickedUpAt,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.timeline = const [],
    this.courier,
    this.courierPosition,
  });

  // Getter alias untuk kompabilitas
  String get trackingNumber => nomorResi;
  String get itemName => 'Paket Pengiriman ($serviceName)';
  String get itemCategory => serviceName;
  String get serviceType => serviceName;

  int get etaMinutes {
    if (estimasiTiba != null) {
      final diff = estimasiTiba!.difference(DateTime.now()).inMinutes;
      return diff > 0 ? diff : 0;
    }
    return 15;
  }

  double get distanceKm => 2.5;

  ShipmentStatus get status => _statusFromCode(statusCode);

  static ShipmentStatus _statusFromCode(String code) {
    switch (code) {
      case 'PENDING':
      case 'CONFIRMED':
        return ShipmentStatus.pending;
      case 'PICKUP_SCHEDULED':
      case 'PICKED_UP':
        return ShipmentStatus.pickedUp;
      case 'IN_TRANSIT':
      case 'AT_SORTING_CENTER':
        return ShipmentStatus.inTransit;
      case 'OUT_FOR_DELIVERY':
        return ShipmentStatus.outForDelivery;
      case 'DELIVERED':
        return ShipmentStatus.delivered;
      case 'CANCELLED':
      case 'RETURNED':
      case 'FAILED_DELIVERY':
        return ShipmentStatus.cancelled;
      default:
        return ShipmentStatus.pending;
    }
  }

  String get formattedTotalBerat {
    if (totalBeratGram >= 1000) {
      final kg = totalBeratGram / 1000.0;
      return '${kg.toStringAsFixed(kg.truncateToDouble() == kg ? 0 : 1)} kg';
    }
    return '$totalBeratGram gram';
  }

  LocationPoint get origin => LocationPoint(
        name: pengirimNama,
        address: pengirimAlamat,
        city: pengirimKota,
        latitude: pengirimLatitude ?? -6.2088,
        longitude: pengirimLongitude ?? 106.8456,
      );

  LocationPoint get destination => LocationPoint(
        name: penerimaNama,
        address: penerimaAlamat,
        city: penerimaKota,
        latitude: penerimaLatitude ?? -6.2088,
        longitude: penerimaLongitude ?? 106.8456,
      );

  bool get isWaitingConfirmation =>
      statusCode == 'PENDING' || statusCode == 'CONFIRMED' || statusId == 1 || statusId == 2;

  bool get isInProcess =>
      statusCode == 'PICKUP_SCHEDULED' ||
      statusCode == 'PICKED_UP' ||
      statusCode == 'AT_SORTING_CENTER' ||
      statusId == 3 ||
      statusId == 4 ||
      statusId == 6;

  bool get isInTransit =>
      statusCode == 'IN_TRANSIT' ||
      statusCode == 'OUT_FOR_DELIVERY' ||
      statusId == 5 ||
      statusId == 7;

  bool get isDelivered => statusCode == 'DELIVERED' || statusId == 8;

  bool get isCancelled =>
      statusCode == 'CANCELLED' || statusCode == 'RETURNED' || statusId == 10 || statusId == 11;

  /// Persentase progres pengiriman (0.0 s/d 1.0)
  double get progressPercentage {
    if (isDelivered) return 1.0;
    if (isCancelled) return 0.0;
    switch (statusCode) {
      case 'PENDING':
        return 0.15;
      case 'CONFIRMED':
        return 0.25;
      case 'PICKUP_SCHEDULED':
        return 0.35;
      case 'PICKED_UP':
        return 0.50;
      case 'AT_SORTING_CENTER':
        return 0.65;
      case 'IN_TRANSIT':
        return 0.75;
      case 'OUT_FOR_DELIVERY':
        return 0.90;
      case 'DELIVERED':
        return 1.0;
      default:
        return 0.20;
    }
  }

  /// Estimasi durasi pengiriman dari tabel m_service_types (estimasi_hari_min & estimasi_hari_max)
  String get estimationDaysDisplay {
    final min = estimasiHariMin;
    final max = estimasiHariMax;
    if (min != null && max != null) {
      if (min == 0 && max == 0) return 'Hari ini';
      if (min == max) return '$min hari kerja';
      return '$min-$max hari kerja';
    } else if (min != null) {
      return '$min hari kerja';
    } else if (max != null) {
      return '$max hari kerja';
    }
    return '1-2 hari kerja';
  }

  /// Estimasi waktu tiba dalam format ramah pengguna
  String get etaDisplay {
    if (isDelivered) return 'Tiba di tujuan';
    if (isCancelled) return 'Pengiriman dibatalkan';
    if (estimasiTiba != null) {
      final now = DateTime.now();
      final diff = estimasiTiba!.difference(now);
      if (diff.isNegative) {
        return 'Tiba hari ini';
      }
      if (diff.inDays > 0) {
        return '${diff.inDays + 1} Hari Kerja';
      }
      if (diff.inHours > 0) {
        return '${diff.inHours} Jam lagi';
      }
      return 'Tiba sebentar lagi';
    }
    return estimationDaysDisplay;
  }

  /// Format rupiah untuk total biaya
  String get formattedTotalBiaya {
    final value = totalBiaya.toInt();
    final digits = value.toString();
    final buffer = StringBuffer('Rp ');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Format tanggal pembuatan
  String get formattedCreatedAt {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = months[createdAt.month];
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  Shipment copyWith({
    String? id,
    String? nomorResi,
    String? barcodeValue,
    int? customerId,
    int? serviceTypeId,
    String? serviceName,
    String? serviceCode,
    int? estimasiHariMin,
    int? estimasiHariMax,
    int? statusId,
    String? statusCode,
    String? statusName,
    String? pengirimNama,
    String? pengirimNoHp,
    String? pengirimAlamat,
    String? pengirimKota,
    double? pengirimLatitude,
    double? pengirimLongitude,
    String? penerimaNama,
    String? penerimaNoHp,
    String? penerimaAlamat,
    String? penerimaKota,
    double? penerimaLatitude,
    double? penerimaLongitude,
    int? totalBeratGram,
    int? totalBarang,
    double? nilaiBarang,
    double? biayaPengiriman,
    double? biayaAsuransi,
    double? totalBiaya,
    String? metodePembayaran,
    String? catatanPengiriman,
    DateTime? estimasiTiba,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ShipmentTimelineStep>? timeline,
    Courier? courier,
    LocationPoint? courierPosition,
  }) {
    return Shipment(
      id: id ?? this.id,
      nomorResi: nomorResi ?? this.nomorResi,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      customerId: customerId ?? this.customerId,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      serviceName: serviceName ?? this.serviceName,
      serviceCode: serviceCode ?? this.serviceCode,
      estimasiHariMin: estimasiHariMin ?? this.estimasiHariMin,
      estimasiHariMax: estimasiHariMax ?? this.estimasiHariMax,
      statusId: statusId ?? this.statusId,
      statusCode: statusCode ?? this.statusCode,
      statusName: statusName ?? this.statusName,
      pengirimNama: pengirimNama ?? this.pengirimNama,
      pengirimNoHp: pengirimNoHp ?? this.pengirimNoHp,
      pengirimAlamat: pengirimAlamat ?? this.pengirimAlamat,
      pengirimKota: pengirimKota ?? this.pengirimKota,
      pengirimLatitude: pengirimLatitude ?? this.pengirimLatitude,
      pengirimLongitude: pengirimLongitude ?? this.pengirimLongitude,
      penerimaNama: penerimaNama ?? this.penerimaNama,
      penerimaNoHp: penerimaNoHp ?? this.penerimaNoHp,
      penerimaAlamat: penerimaAlamat ?? this.penerimaAlamat,
      penerimaKota: penerimaKota ?? this.penerimaKota,
      penerimaLatitude: penerimaLatitude ?? this.penerimaLatitude,
      penerimaLongitude: penerimaLongitude ?? this.penerimaLongitude,
      totalBeratGram: totalBeratGram ?? this.totalBeratGram,
      totalBarang: totalBarang ?? this.totalBarang,
      nilaiBarang: nilaiBarang ?? this.nilaiBarang,
      biayaPengiriman: biayaPengiriman ?? this.biayaPengiriman,
      biayaAsuransi: biayaAsuransi ?? this.biayaAsuransi,
      totalBiaya: totalBiaya ?? this.totalBiaya,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      catatanPengiriman: catatanPengiriman ?? this.catatanPengiriman,
      estimasiTiba: estimasiTiba ?? this.estimasiTiba,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeline: timeline ?? this.timeline,
      courier: courier ?? this.courier,
      courierPosition: courierPosition ?? this.courierPosition,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nomorResi,
        barcodeValue,
        customerId,
        serviceTypeId,
        serviceName,
        serviceCode,
        estimasiHariMin,
        estimasiHariMax,
        statusId,
        statusCode,
        statusName,
        pengirimNama,
        pengirimNoHp,
        pengirimAlamat,
        pengirimKota,
        pengirimLatitude,
        pengirimLongitude,
        penerimaNama,
        penerimaNoHp,
        penerimaAlamat,
        penerimaKota,
        penerimaLatitude,
        penerimaLongitude,
        totalBeratGram,
        totalBarang,
        nilaiBarang,
        biayaPengiriman,
        biayaAsuransi,
        totalBiaya,
        metodePembayaran,
        catatanPengiriman,
        estimasiTiba,
        pickedUpAt,
        deliveredAt,
        createdAt,
        updatedAt,
        timeline,
        courier,
        courierPosition,
      ];
}
