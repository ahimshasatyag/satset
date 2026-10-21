import 'package:geolocator/geolocator.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackTimelineStepModel extends LiveTrackTimelineStep {
  const LiveTrackTimelineStepModel({
    required super.id,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    super.locationName,
    super.latitude,
    super.longitude,
    required super.notes,
    required super.createdAt,
    super.isCurrent = false,
  });

  factory LiveTrackTimelineStepModel.fromDatabase(
    Map<String, dynamic> map, {
    bool isCurrent = false,
  }) {
    final statusMap = map['m_shipment_statuses'] as Map<String, dynamic>?;
    final statusId = (map['status_id'] as num?)?.toInt() ??
        (statusMap?['id'] as num?)?.toInt() ??
        1;
    final statusCode = statusMap?['kode']?.toString() ??
        map['status_code']?.toString() ??
        'IN_TRANSIT';
    final statusName = statusMap?['nama_status']?.toString() ??
        map['status_name']?.toString() ??
        'Dalam Perjalanan';
    final notes = map['catatan']?.toString() ??
        map['deskripsi']?.toString() ??
        'Paket sedang diproses';
    final locationName =
        map['lokasi_nama']?.toString() ?? map['location']?.toString();
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    final createdAt = map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    return LiveTrackTimelineStepModel(
      id: map['id']?.toString() ?? '',
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      locationName: locationName,
      latitude: lat,
      longitude: lng,
      notes: notes,
      createdAt: createdAt,
      isCurrent: isCurrent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'statusId': statusId,
      'statusCode': statusCode,
      'statusName': statusName,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}

class LiveTrackShipmentModel extends LiveTrackShipment {
  const LiveTrackShipmentModel({
    required super.id,
    required super.trackingNumber,
    required super.barcodeValue,
    required super.customerId,
    required super.serviceTypeId,
    required super.serviceTypeName,
    required super.serviceTypeCode,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    required super.statusDescription,
    required super.direction,
    required super.filterStatus,
    required super.senderName,
    required super.senderPhone,
    required super.senderAddress,
    required super.senderCity,
    super.senderLatitude,
    super.senderLongitude,
    required super.receiverName,
    required super.receiverPhone,
    required super.receiverAddress,
    required super.receiverCity,
    super.receiverPostalCode,
    super.receiverLatitude,
    super.receiverLongitude,
    super.courierName,
    super.courierPhone,
    super.courierVehicle,
    super.courierLatitude,
    super.courierLongitude,
    super.courierLocationUpdatedAt,
    super.courierHeading,
    super.courierSpeed,
    super.etaMinutes,
    super.distanceKm,
    super.estimatedArrival,
    required super.totalPrice,
    required super.totalWeightGram,
    super.shippingNotes,
    required super.createdAt,
    required super.updatedAt,
    super.timeline = const [],
  });

  /// Factory untuk memetakan data langsung dari tabel PostgreSQL Supabase
  factory LiveTrackShipmentModel.fromDatabase(
    Map<String, dynamic> map, {
    int? currentCustomerId,
    String? currentUserPhone,
    Map<String, dynamic>? latestLocation,
  }) {
    // 1. Ekstrak Status dari joined m_shipment_statuses
    final statusMap = map['m_shipment_statuses'] as Map<String, dynamic>?;
    final int statusId = (map['status_id'] as num?)?.toInt() ??
        (statusMap?['id'] as num?)?.toInt() ??
        1;
    final String statusCode = (statusMap?['kode'] as String?) ??
        (map['status_code'] as String?) ??
        _statusCodeFromId(statusId);
    final String statusName = (statusMap?['nama_status'] as String?) ??
        (map['status_name'] as String?) ??
        _statusNameFromCode(statusCode);

    // 2. Ekstrak Service Type dari joined m_service_types
    final serviceMap = map['m_service_types'] as Map<String, dynamic>?;
    final int serviceTypeId = (map['service_type_id'] as num?)?.toInt() ??
        (serviceMap?['id'] as num?)?.toInt() ??
        1;
    final String serviceName = (serviceMap?['nama_layanan'] as String?) ??
        (map['service_name'] as String?) ??
        'Reguler';
    final String serviceCode = (serviceMap?['kode'] as String?) ??
        (map['service_code'] as String?) ??
        'REG';

    // 3. Ekstrak Timeline dari joined t_shipment_tracking
    final List<LiveTrackTimelineStep> timelineList = [];
    final trackingRaw = map['t_shipment_tracking'];
    if (trackingRaw is List && trackingRaw.isNotEmpty) {
      // Urutkan riwayat tracking secara kronologis (terlama ke terbaru)
      final rawList = List<Map<String, dynamic>>.from(
        trackingRaw.whereType<Map<String, dynamic>>(),
      );
      rawList.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });

      for (int i = 0; i < rawList.length; i++) {
        timelineList.add(LiveTrackTimelineStepModel.fromDatabase(
          rawList[i],
          isCurrent: i == rawList.length - 1,
        ));
      }
    }

    // 4. Resolusi Posisi Kurir Terkini dari t_shipment_locations atau t_shipment_tracking
    double? courierLat;
    double? courierLng;
    DateTime? courierUpdatedAt;
    double? courierHeading;
    double? courierSpeed;

    if (latestLocation != null) {
      courierLat = (latestLocation['latitude'] as num?)?.toDouble();
      courierLng = (latestLocation['longitude'] as num?)?.toDouble();
      courierHeading = (latestLocation['heading'] as num?)?.toDouble();
      courierSpeed = (latestLocation['speed'] as num?)?.toDouble();
      final updateStr = latestLocation['updated_at']?.toString() ??
          latestLocation['created_at']?.toString();
      if (updateStr != null) {
        courierUpdatedAt = DateTime.tryParse(updateStr);
      }
    }

    // Jika t_shipment_locations belum ada data koordinat, cek jejak terbaru di timeline
    if (courierLat == null && courierLng == null && timelineList.isNotEmpty) {
      final latestWithCoord = timelineList.lastWhere(
        (step) => step.latitude != null && step.longitude != null,
        orElse: () => timelineList.last,
      );
      if (latestWithCoord.latitude != null && latestWithCoord.longitude != null) {
        courierLat = latestWithCoord.latitude;
        courierLng = latestWithCoord.longitude;
        courierUpdatedAt = latestWithCoord.createdAt;
      }
    }

    // 5. Ekstrak Data Pengirim & Penerima
    final destLat = (map['penerima_latitude'] as num?)?.toDouble();
    final destLng = (map['penerima_longitude'] as num?)?.toDouble();
    final senderLat = (map['pengirim_latitude'] as num?)?.toDouble();
    final senderLng = (map['pengirim_longitude'] as num?)?.toDouble();

    // 6. Hitung Jarak & Estimasi Waktu Tiba (HANYA jika data posisi kurir nyata tersedia)
    double? calculatedDistanceKm;
    int? calculatedEtaMinutes;

    if (courierLat != null &&
        courierLng != null &&
        destLat != null &&
        destLng != null &&
        courierLat != 0.0 &&
        courierLng != 0.0 &&
        destLat != 0.0 &&
        destLng != 0.0) {
      try {
        final distMeters = Geolocator.distanceBetween(
          courierLat,
          courierLng,
          destLat,
          destLng,
        );
        calculatedDistanceKm = double.parse((distMeters / 1000).toStringAsFixed(1));
        // Kecepatan rata-rata kurir sepeda motor dalam kota ~25-30 km/jam (~450m/menit)
        calculatedEtaMinutes = (distMeters / 450).round().clamp(3, 180);
      } catch (_) {}
    }

    // 7. Resolusi Arah (Outgoing vs Incoming)
    final int customerId = (map['customer_id'] as num?)?.toInt() ?? 0;
    final String receiverPhone = (map['penerima_no_hp'] as String?)?.trim() ?? '';

    OrderDirection dir = OrderDirection.outgoing;
    if (currentUserPhone != null &&
        currentUserPhone.isNotEmpty &&
        receiverPhone.isNotEmpty &&
        receiverPhone.endsWith(
            currentUserPhone.substring(currentUserPhone.length > 8 ? currentUserPhone.length - 8 : 0))) {
      dir = OrderDirection.incoming;
    } else if (currentCustomerId != null && customerId == currentCustomerId) {
      dir = OrderDirection.outgoing;
    }

    // 8. Resolusi Filter Status
    final filterStatus = _resolveFilterStatus(statusId, statusCode);

    final createdAt = map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = map['updated_at'] != null
        ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
        : createdAt;
    final estimasiTiba = map['estimasi_tiba'] != null
        ? DateTime.tryParse(map['estimasi_tiba'].toString())
        : null;

    final notes = map['catatan_pengiriman'] as String?;
    final resi = (map['nomor_resi'] as String?)?.trim() ?? '';
    final barcode = (map['barcode_value'] as String?)?.trim() ?? resi;

    // Nama kurir dari relasi atau placeholder informatif
    final String? courierName = map['courier_name'] as String? ??
        (statusId >= 4 && statusId <= 7 ? 'Kurir SatSet Ekspedisi' : null);
    final String? courierPhone = map['courier_phone'] as String? ??
        (statusId >= 4 && statusId <= 7 ? '+628123456789' : null);
    final String? courierVehicle = map['courier_vehicle'] as String? ??
        (statusId >= 4 && statusId <= 7 ? 'Motor SatSet' : null);

    return LiveTrackShipmentModel(
      id: map['id']?.toString() ?? '',
      trackingNumber: resi,
      barcodeValue: barcode,
      customerId: customerId,
      serviceTypeId: serviceTypeId,
      serviceTypeName: serviceName,
      serviceTypeCode: serviceCode,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      statusDescription: _statusDescriptionFromCode(statusCode, statusName),
      direction: dir,
      filterStatus: filterStatus,
      senderName: (map['pengirim_nama'] as String?) ?? 'Pengirim',
      senderPhone: (map['pengirim_no_hp'] as String?) ?? '',
      senderAddress: (map['pengirim_alamat'] as String?) ?? '',
      senderCity: (map['pengirim_kota'] as String?) ?? 'Kota Asal',
      senderLatitude: senderLat,
      senderLongitude: senderLng,
      receiverName: (map['penerima_nama'] as String?) ?? 'Penerima',
      receiverPhone: receiverPhone,
      receiverAddress: (map['penerima_alamat'] as String?) ?? '',
      receiverCity: (map['penerima_kota'] as String?) ?? 'Kota Tujuan',
      receiverPostalCode: map['penerima_kode_pos'] as String?,
      receiverLatitude: destLat,
      receiverLongitude: destLng,
      courierName: courierName,
      courierPhone: courierPhone,
      courierVehicle: courierVehicle,
      courierLatitude: courierLat,
      courierLongitude: courierLng,
      courierLocationUpdatedAt: courierUpdatedAt,
      courierHeading: courierHeading,
      courierSpeed: courierSpeed,
      etaMinutes: calculatedEtaMinutes,
      distanceKm: calculatedDistanceKm,
      estimatedArrival: estimasiTiba,
      totalPrice: (map['total_biaya'] as num?)?.toInt() ?? 0,
      totalWeightGram: (map['total_berat_gram'] as num?)?.toInt() ?? 0,
      shippingNotes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      timeline: timelineList,
    );
  }

  static OrderFilterStatus _resolveFilterStatus(int statusId, String statusCode) {
    final code = statusCode.toUpperCase();
    if (statusId == 1 ||
        statusId == 2 ||
        statusId == 3 ||
        code == 'PENDING' ||
        code == 'CONFIRMED' ||
        code == 'PICKUP_SCHEDULED') {
      return OrderFilterStatus.waitingPickup;
    } else if (statusId == 4 ||
        statusId == 5 ||
        statusId == 6 ||
        statusId == 7 ||
        code == 'PICKED_UP' ||
        code == 'IN_TRANSIT' ||
        code == 'AT_SORTING_CENTER' ||
        code == 'OUT_FOR_DELIVERY') {
      return OrderFilterStatus.inDelivery;
    } else if (statusId >= 8 ||
        code == 'DELIVERED' ||
        code == 'FAILED_DELIVERY' ||
        code == 'RETURNED' ||
        code == 'CANCELLED') {
      return OrderFilterStatus.completed;
    }
    return OrderFilterStatus.all;
  }

  static String _statusCodeFromId(int id) {
    switch (id) {
      case 1:
        return 'PENDING';
      case 2:
        return 'CONFIRMED';
      case 3:
        return 'PICKUP_SCHEDULED';
      case 4:
        return 'PICKED_UP';
      case 5:
        return 'IN_TRANSIT';
      case 6:
        return 'AT_SORTING_CENTER';
      case 7:
        return 'OUT_FOR_DELIVERY';
      case 8:
        return 'DELIVERED';
      case 9:
        return 'FAILED_DELIVERY';
      case 10:
        return 'RETURNED';
      case 11:
        return 'CANCELLED';
      default:
        return 'IN_TRANSIT';
    }
  }

  static String _statusNameFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'CONFIRMED':
        return 'Terkonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Dijadwalkan untuk Pickup';
      case 'PICKED_UP':
        return 'Telah Dijemput';
      case 'IN_TRANSIT':
        return 'Dalam Perjalanan';
      case 'AT_SORTING_CENTER':
        return 'Berada di Pusat Sortir';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar Kurir';
      case 'DELIVERED':
        return 'Terkirim';
      case 'FAILED_DELIVERY':
        return 'Gagal Diantar';
      case 'RETURNED':
        return 'Dikembalikan';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return 'Dalam Proses';
    }
  }

  static String _statusDescriptionFromCode(String code, String name) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return 'Pesanan telah dibuat dan menunggu konfirmasi penjemputan';
      case 'CONFIRMED':
        return 'Pesanan telah dikonfirmasi dan menunggu jadwal kurir';
      case 'PICKUP_SCHEDULED':
        return 'Kurir telah ditugaskan dan dijadwalkan menuju lokasi penjemputan';
      case 'PICKED_UP':
        return 'Paket telah berhasil dijemput oleh kurir';
      case 'IN_TRANSIT':
        return 'Paket sedang bergerak menuju fasilitas sortir atau kota tujuan';
      case 'AT_SORTING_CENTER':
        return 'Paket tiba dan sedang diproses di pusat sortir SatSet';
      case 'OUT_FOR_DELIVERY':
        return 'Kurir sedang membawa paket menuju alamat penerima';
      case 'DELIVERED':
        return 'Paket telah berhasil diterima di alamat tujuan';
      case 'FAILED_DELIVERY':
        return 'Pengantaran terkendala, kurir akan mencoba kembali';
      case 'RETURNED':
        return 'Paket dikembalikan ke pengirim';
      case 'CANCELLED':
        return 'Pengiriman telah dibatalkan';
      default:
        return name;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'barcodeValue': barcodeValue,
      'customerId': customerId,
      'serviceTypeId': serviceTypeId,
      'serviceTypeName': serviceTypeName,
      'serviceTypeCode': serviceTypeCode,
      'statusId': statusId,
      'statusCode': statusCode,
      'statusName': statusName,
      'statusDescription': statusDescription,
      'direction': direction.name,
      'filterStatus': filterStatus.name,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderAddress': senderAddress,
      'senderCity': senderCity,
      'senderLatitude': senderLatitude,
      'senderLongitude': senderLongitude,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverAddress': receiverAddress,
      'receiverCity': receiverCity,
      'receiverPostalCode': receiverPostalCode,
      'receiverLatitude': receiverLatitude,
      'receiverLongitude': receiverLongitude,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'courierVehicle': courierVehicle,
      'courierLatitude': courierLatitude,
      'courierLongitude': courierLongitude,
      'courierLocationUpdatedAt': courierLocationUpdatedAt?.toIso8601String(),
      'courierHeading': courierHeading,
      'courierSpeed': courierSpeed,
      'etaMinutes': etaMinutes,
      'distanceKm': distanceKm,
      'estimatedArrival': estimatedArrival?.toIso8601String(),
      'totalPrice': totalPrice,
      'totalWeightGram': totalWeightGram,
      'shippingNotes': shippingNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timeline': timeline
          .map((step) => (step is LiveTrackTimelineStepModel)
              ? step.toJson()
              : {
                  'id': step.id,
                  'statusId': step.statusId,
                  'statusCode': step.statusCode,
                  'statusName': step.statusName,
                  'locationName': step.locationName,
                  'latitude': step.latitude,
                  'longitude': step.longitude,
                  'notes': step.notes,
                  'createdAt': step.createdAt.toIso8601String(),
                  'isCurrent': step.isCurrent,
                })
          .toList(),
    };
  }

  factory LiveTrackShipmentModel.fromJson(Map<String, dynamic> json) {
    final dir = (json['direction'] == 'incoming')
        ? OrderDirection.incoming
        : OrderDirection.outgoing;

    OrderFilterStatus fStatus;
    switch (json['filterStatus']?.toString().toLowerCase()) {
      case 'waitingpickup':
        fStatus = OrderFilterStatus.waitingPickup;
        break;
      case 'indelivery':
        fStatus = OrderFilterStatus.inDelivery;
        break;
      case 'completed':
        fStatus = OrderFilterStatus.completed;
        break;
      default:
        fStatus = OrderFilterStatus.all;
    }

    final rawTimeline = json['timeline'] as List?;
    final List<LiveTrackTimelineStep> timelineList = [];
    if (rawTimeline != null) {
      for (final item in rawTimeline) {
        if (item is Map<String, dynamic>) {
          timelineList.add(LiveTrackTimelineStepModel.fromDatabase(item));
        }
      }
    }

    return LiveTrackShipmentModel(
      id: json['id']?.toString() ?? '',
      trackingNumber: json['trackingNumber']?.toString() ?? '',
      barcodeValue: json['barcodeValue']?.toString() ?? '',
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      serviceTypeId: (json['serviceTypeId'] as num?)?.toInt() ?? 1,
      serviceTypeName: json['serviceTypeName']?.toString() ?? 'Reguler',
      serviceTypeCode: json['serviceTypeCode']?.toString() ?? 'REG',
      statusId: (json['statusId'] as num?)?.toInt() ?? 1,
      statusCode: json['statusCode']?.toString() ?? 'IN_TRANSIT',
      statusName: json['statusName']?.toString() ?? 'Dalam Perjalanan',
      statusDescription: json['statusDescription']?.toString() ?? '',
      direction: dir,
      filterStatus: fStatus,
      senderName: json['senderName']?.toString() ?? '',
      senderPhone: json['senderPhone']?.toString() ?? '',
      senderAddress: json['senderAddress']?.toString() ?? '',
      senderCity: json['senderCity']?.toString() ?? '',
      senderLatitude: (json['senderLatitude'] as num?)?.toDouble(),
      senderLongitude: (json['senderLongitude'] as num?)?.toDouble(),
      receiverName: json['receiverName']?.toString() ?? '',
      receiverPhone: json['receiverPhone']?.toString() ?? '',
      receiverAddress: json['receiverAddress']?.toString() ?? '',
      receiverCity: json['receiverCity']?.toString() ?? '',
      receiverPostalCode: json['receiverPostalCode']?.toString(),
      receiverLatitude: (json['receiverLatitude'] as num?)?.toDouble(),
      receiverLongitude: (json['receiverLongitude'] as num?)?.toDouble(),
      courierName: json['courierName']?.toString(),
      courierPhone: json['courierPhone']?.toString(),
      courierVehicle: json['courierVehicle']?.toString(),
      courierLatitude: (json['courierLatitude'] as num?)?.toDouble(),
      courierLongitude: (json['courierLongitude'] as num?)?.toDouble(),
      courierLocationUpdatedAt: json['courierLocationUpdatedAt'] != null
          ? DateTime.tryParse(json['courierLocationUpdatedAt'] as String)
          : null,
      courierHeading: (json['courierHeading'] as num?)?.toDouble(),
      courierSpeed: (json['courierSpeed'] as num?)?.toDouble(),
      etaMinutes: json['etaMinutes'] as int?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.tryParse(json['estimatedArrival'] as String)
          : null,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      totalWeightGram: (json['totalWeightGram'] as num?)?.toInt() ?? 0,
      shippingNotes: json['shippingNotes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      timeline: timelineList,
    );
  }
}
