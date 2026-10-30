import '../../domain/entities/shipment.dart';

class ShipmentTimelineStepModel extends ShipmentTimelineStep {
  const ShipmentTimelineStepModel({
    super.id = '',
    required super.title,
    required super.description,
    super.location,
    super.latitude,
    super.longitude,
    required super.timestamp,
    super.isCompleted = false,
    super.isCurrent = false,
  });

  /// Factory untuk parse dari baris tabel Supabase t_shipment_tracking
  factory ShipmentTimelineStepModel.fromDatabase(Map<String, dynamic> map, {bool isCurrent = false}) {
    final statusMap = map['m_shipment_statuses'] as Map<String, dynamic>?;
    final statusName = statusMap?['nama_status'] as String? ??
        map['status_name'] as String? ??
        map['status'] as String? ??
        'Pembaruan Status';
    final catatan = map['catatan'] as String? ?? map['deskripsi'] as String? ?? '';
    final lokasi = map['lokasi_nama'] as String? ?? map['location'] as String?;
    final lat = (map['latitude'] as num?)?.toDouble();
    final lng = (map['longitude'] as num?)?.toDouble();
    final createdAtStr = map['created_at']?.toString();
    final timestamp = createdAtStr != null
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();

    return ShipmentTimelineStepModel(
      id: map['id']?.toString() ?? '',
      title: statusName,
      description: catatan.isNotEmpty ? catatan : 'Status paket: $statusName',
      location: lokasi,
      latitude: lat,
      longitude: lng,
      timestamp: timestamp,
      isCompleted: true,
      isCurrent: isCurrent,
    );
  }

  factory ShipmentTimelineStepModel.fromJson(Map<String, dynamic> json) {
    return ShipmentTimelineStepModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
      'isCurrent': isCurrent,
    };
  }
}

class ShipmentModel extends Shipment {
  const ShipmentModel({
    required super.id,
    required super.nomorResi,
    required super.barcodeValue,
    required super.customerId,
    required super.serviceTypeId,
    required super.serviceName,
    super.serviceCode = 'REG',
    super.estimasiHariMin,
    super.estimasiHariMax,
    required super.statusId,
    required super.statusCode,
    required super.statusName,
    required super.pengirimNama,
    required super.pengirimNoHp,
    required super.pengirimAlamat,
    super.pengirimKota = 'Jakarta',
    super.pengirimLatitude,
    super.pengirimLongitude,
    required super.penerimaNama,
    required super.penerimaNoHp,
    required super.penerimaAlamat,
    super.penerimaKota = 'Jakarta',
    super.penerimaLatitude,
    super.penerimaLongitude,
    super.totalBeratGram = 0,
    super.totalBarang = 1,
    super.nilaiBarang = 0.0,
    super.biayaPengiriman = 0.0,
    super.biayaAsuransi = 0.0,
    super.totalBiaya = 0.0,
    super.metodePembayaran = 'TRANSFER',
    super.catatanPengiriman,
    super.estimasiTiba,
    super.pickedUpAt,
    super.deliveredAt,
    required super.createdAt,
    required super.updatedAt,
    super.timeline = const [],
    super.courier,
    super.courierPosition,
  });

  /// Factory untuk mengonversi data dari relasi Supabase t_shipments
  factory ShipmentModel.fromDatabase(Map<String, dynamic> map) {
    // 1. Ekstrak Status dari joined m_shipment_statuses jika ada
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

    // 2. Ekstrak Service Type dari joined m_service_types jika ada
    final serviceRaw = map['m_service_types'];
    final Map<String, dynamic>? serviceMap = serviceRaw is Map<String, dynamic>
        ? serviceRaw
        : (serviceRaw is List && serviceRaw.isNotEmpty)
            ? serviceRaw.first as Map<String, dynamic>
            : null;
    final int serviceTypeId = (map['service_type_id'] as num?)?.toInt() ??
        (serviceMap?['id'] as num?)?.toInt() ??
        1;
    final String serviceName = (serviceMap?['nama_layanan'] as String?) ??
        (map['service_name'] as String?) ??
        'Reguler';
    final String serviceCode = (serviceMap?['kode'] as String?) ??
        (map['service_code'] as String?) ??
        'REG';

    // Ekstrak estimasi hari kerja dari tabel m_service_types (estimasi_hari_min, estimasi_hari_max)
    int? estimasiHariMin = (serviceMap?['estimasi_hari_min'] as num?)?.toInt() ??
        (map['estimasi_hari_min'] as num?)?.toInt();
    int? estimasiHariMax = (serviceMap?['estimasi_hari_max'] as num?)?.toInt() ??
        (map['estimasi_hari_max'] as num?)?.toInt();

    // Default fallback jika nilai belum diatur
    if (estimasiHariMin == null && estimasiHariMax == null) {
      if (serviceCode.toUpperCase() == 'REG' ||
          serviceName.toLowerCase().contains('reguler')) {
        estimasiHariMin = 1;
        estimasiHariMax = 2;
      } else if (serviceCode.toUpperCase() == 'EXP' ||
          serviceName.toLowerCase().contains('express')) {
        estimasiHariMin = 1;
        estimasiHariMax = 1;
      } else if (serviceCode.toUpperCase() == 'SAMEDAY' ||
          serviceCode.toUpperCase() == 'INST') {
        estimasiHariMin = 0;
        estimasiHariMax = 0;
      }
    }

    // 3. Ekstrak Timeline jika t_shipment_tracking di-include
    List<ShipmentTimelineStepModel> timelineList = [];
    final trackingRaw = map['t_shipment_tracking'];
    if (trackingRaw is List && trackingRaw.isNotEmpty) {
      for (int i = 0; i < trackingRaw.length; i++) {
        final item = trackingRaw[i];
        if (item is Map<String, dynamic>) {
          timelineList.add(ShipmentTimelineStepModel.fromDatabase(
            item,
            isCurrent: i == trackingRaw.length - 1,
          ));
        }
      }
    }

    // 4. Koordinat & Kurir dari tracking terakhir jika tersedia
    Courier? courier;
    LocationPoint? courierPos;
    if (timelineList.isNotEmpty) {
      final lastStep = timelineList.last;
      if (lastStep.latitude != null && lastStep.longitude != null) {
        courierPos = LocationPoint(
          name: lastStep.location ?? 'Posisi Kurir Saat Ini',
          address: lastStep.description,
          city: map['penerima_kota'] as String? ?? 'Jakarta',
          latitude: lastStep.latitude!,
          longitude: lastStep.longitude!,
        );
        courier = Courier(
          id: 'cr-${map['id']}',
          name: 'Kurir SatSet',
          phone: '+6281234567890',
          photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          vehicleType: serviceName.contains('Instant') ? 'Motor Flash' : 'Motor SatSet',
          vehiclePlate: 'B ${map['id']} SAT',
          latitude: lastStep.latitude!,
          longitude: lastStep.longitude!,
        );
      }
    }

    final createdAt = map['created_at'] != null
        ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = map['updated_at'] != null
        ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
        : createdAt;
    final estimasiTiba = map['estimasi_tiba'] != null
        ? DateTime.tryParse(map['estimasi_tiba'].toString())
        : null;
    final pickedUpAt = map['picked_up_at'] != null
        ? DateTime.tryParse(map['picked_up_at'].toString())
        : null;
    final deliveredAt = map['delivered_at'] != null
        ? DateTime.tryParse(map['delivered_at'].toString())
        : null;

    final String resi = (map['nomor_resi'] as String?)?.isNotEmpty == true
        ? map['nomor_resi'] as String
        : 'SST-${map['id']}';
    final String barcode = (map['barcode_value'] as String?)?.isNotEmpty == true
        ? map['barcode_value'] as String
        : resi;

    return ShipmentModel(
      id: map['id']?.toString() ?? '',
      nomorResi: resi,
      barcodeValue: barcode,
      customerId: (map['customer_id'] as num?)?.toInt() ?? 0,
      serviceTypeId: serviceTypeId,
      serviceName: serviceName,
      serviceCode: serviceCode,
      estimasiHariMin: estimasiHariMin,
      estimasiHariMax: estimasiHariMax,
      statusId: statusId,
      statusCode: statusCode,
      statusName: statusName,
      pengirimNama: map['pengirim_nama'] as String? ?? 'Pengirim',
      pengirimNoHp: map['pengirim_no_hp'] as String? ?? '',
      pengirimAlamat: map['pengirim_alamat'] as String? ?? '',
      pengirimKota: map['pengirim_kota'] as String? ?? 'Jakarta',
      pengirimLatitude: (map['pengirim_latitude'] as num?)?.toDouble(),
      pengirimLongitude: (map['pengirim_longitude'] as num?)?.toDouble(),
      penerimaNama: map['penerima_nama'] as String? ?? 'Penerima',
      penerimaNoHp: map['penerima_no_hp'] as String? ?? '',
      penerimaAlamat: map['penerima_alamat'] as String? ?? '',
      penerimaKota: map['penerima_kota'] as String? ?? 'Jakarta',
      penerimaLatitude: (map['penerima_latitude'] as num?)?.toDouble(),
      penerimaLongitude: (map['penerima_longitude'] as num?)?.toDouble(),
      totalBeratGram: (map['total_berat_gram'] as num?)?.toInt() ?? 0,
      totalBarang: (map['total_barang'] as num?)?.toInt() ?? 1,
      nilaiBarang: (map['nilai_barang'] as num?)?.toDouble() ?? 0.0,
      biayaPengiriman: (map['biaya_pengiriman'] as num?)?.toDouble() ?? 0.0,
      biayaAsuransi: (map['biaya_asuransi'] as num?)?.toDouble() ?? 0.0,
      totalBiaya: (map['total_biaya'] as num?)?.toDouble() ?? 0.0,
      metodePembayaran: map['metode_pembayaran'] as String? ?? 'TRANSFER',
      catatanPengiriman: map['catatan_pengiriman'] as String?,
      estimasiTiba: estimasiTiba,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      timeline: timelineList,
      courier: courier,
      courierPosition: courierPos,
    );
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
        return 'PENDING';
    }
  }

  static String _statusNameFromCode(String code) {
    switch (code) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'CONFIRMED':
        return 'Pengiriman Dikonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Menunggu Penjemputan';
      case 'PICKED_UP':
        return 'Paket Dijemput';
      case 'IN_TRANSIT':
        return 'Dalam Perjalanan';
      case 'AT_SORTING_CENTER':
        return 'Tiba di Gudang Sortir';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar';
      case 'DELIVERED':
        return 'Paket Diterima';
      case 'FAILED_DELIVERY':
        return 'Pengantaran Gagal';
      case 'RETURNED':
        return 'Paket Dikembalikan';
      case 'CANCELLED':
        return 'Pengiriman Dibatalkan';
      default:
        return 'Menunggu Konfirmasi';
    }
  }

  factory ShipmentModel.fromJson(Map<String, dynamic> json) =>
      ShipmentModel.fromDatabase(json);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomor_resi': nomorResi,
      'barcode_value': barcodeValue,
      'customer_id': customerId,
      'service_type_id': serviceTypeId,
      'service_name': serviceName,
      'service_code': serviceCode,
      'estimasi_hari_min': estimasiHariMin,
      'estimasi_hari_max': estimasiHariMax,
      'status_id': statusId,
      'status_code': statusCode,
      'status_name': statusName,
      'pengirim_nama': pengirimNama,
      'pengirim_no_hp': pengirimNoHp,
      'pengirim_alamat': pengirimAlamat,
      'pengirim_kota': pengirimKota,
      'pengirim_latitude': pengirimLatitude,
      'pengirim_longitude': pengirimLongitude,
      'penerima_nama': penerimaNama,
      'penerima_no_hp': penerimaNoHp,
      'penerima_alamat': penerimaAlamat,
      'penerima_kota': penerimaKota,
      'penerima_latitude': penerimaLatitude,
      'penerima_longitude': penerimaLongitude,
      'total_berat_gram': totalBeratGram,
      'total_barang': totalBarang,
      'nilai_barang': nilaiBarang,
      'biaya_pengiriman': biayaPengiriman,
      'biaya_asuransi': biayaAsuransi,
      'total_biaya': totalBiaya,
      'metode_pembayaran': metodePembayaran,
      'catatan_pengiriman': catatanPengiriman,
      'estimasi_tiba': estimasiTiba?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
