import '../../domain/entities/admin_delivery_detail.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

class AdminDeliveryDetailModel extends AdminDeliveryDetail {
  const AdminDeliveryDetailModel({
    required super.id,
    required super.nomorResi,
    required super.barcodeValue,
    super.statusId,
    required super.statusKode,
    required super.statusNama,
    super.serviceTypeId,
    required super.serviceKode,
    required super.serviceNama,
    super.serviceEstimasi,
    super.customerId,
    required super.customerNama,
    required super.customerEmail,
    required super.customerNoHp,
    required super.pengirimNama,
    required super.pengirimNoHp,
    required super.pengirimAlamat,
    required super.pengirimKota,
    super.pengirimKodePos,
    super.pengirimLatitude,
    super.pengirimLongitude,
    required super.penerimaNama,
    required super.penerimaNoHp,
    required super.penerimaAlamat,
    required super.penerimaKota,
    super.penerimaKodePos,
    super.penerimaLatitude,
    super.penerimaLongitude,
    required super.totalBeratGram,
    required super.panjangCm,
    required super.lebarCm,
    required super.tinggiCm,
    required super.totalBarang,
    super.nilaiBarang,
    super.catatanPengiriman,
    required super.biayaPengiriman,
    required super.biayaAsuransi,
    required super.biayaLayananTambahan,
    required super.diskon,
    required super.totalBiaya,
    required super.metodePembayaran,
    required super.statusPembayaran,
    super.nomorPembayaran,
    super.providerPembayaran,
    super.paidAt,
    super.assignmentId,
    super.courierId,
    super.courierNama,
    super.courierCode,
    super.courierEmail,
    super.courierPhone,
    super.assignedAt,
    super.acceptedAt,
    super.completedAt,
    super.assignmentNotes,
    super.lastCourierLocation,
    super.createdAt,
    super.updatedAt,
    super.estimasiTiba,
    super.pickedUpAt,
    super.deliveredAt,
    super.cancelledAt,
    required super.trackingHistory,
  });

  factory AdminDeliveryDetailModel.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? customerMap,
    Map<String, dynamic>? assignmentMap,
    Map<String, dynamic>? courierMap,
    List<Map<String, dynamic>> trackingList = const [],
    Map<String, dynamic>? lastLocationMap,
  }) {
    final statusMap = map['m_shipment_statuses'] is Map<String, dynamic>
        ? map['m_shipment_statuses'] as Map<String, dynamic>
        : <String, dynamic>{};

    final serviceMap = map['m_service_types'] is Map<String, dynamic>
        ? map['m_service_types'] as Map<String, dynamic>
        : <String, dynamic>{};

    final userMap = customerMap ??
        (map['m_users'] is Map<String, dynamic>
            ? map['m_users'] as Map<String, dynamic>
            : <String, dynamic>{});

    Map<String, dynamic> paymentMap = {};
    if (map['t_shipment_payments'] is List &&
        (map['t_shipment_payments'] as List).isNotEmpty) {
      paymentMap = Map<String, dynamic>.from(
        (map['t_shipment_payments'] as List).first as Map,
      );
    } else if (map['t_shipment_payments'] is Map<String, dynamic>) {
      paymentMap = map['t_shipment_payments'] as Map<String, dynamic>;
    }

    final statusId = int.tryParse(
      (statusMap['id'] ?? map['status_id'])?.toString() ?? '',
    );
    final statusCode =
        (statusMap['kode'] ?? _resolveStatusCode(statusId ?? 1)).toString().toUpperCase();
    final statusName =
        (statusMap['nama_status'] ?? AdminStatusHelper.getStatusLabel(statusCode)).toString();

    final minDays = serviceMap['estimasi_hari_min'];
    final maxDays = serviceMap['estimasi_hari_max'];
    String? estimasiStr;
    if (minDays != null && maxDays != null) {
      estimasiStr = '$minDays - $maxDays Hari Kerja';
    }

    final paymentMethod =
        (paymentMap['metode_pembayaran'] ?? map['metode_pembayaran'] ?? 'TRANSFER')
            .toString();
    final paymentStatus = (paymentMap['status_pembayaran'] ??
            (paymentMethod.toUpperCase() == 'COD' ? 'COD' : 'PAID'))
        .toString();

    // Parse riwayat pelacakan secara berurutan (terbaru di atas)
    final parsedTrackings = trackingList.map((t) {
      final tStatusMap = t['m_shipment_statuses'] is Map<String, dynamic>
          ? t['m_shipment_statuses'] as Map<String, dynamic>
          : <String, dynamic>{};
      final tEmpMap = t['m_employee'] is Map<String, dynamic>
          ? t['m_employee'] as Map<String, dynamic>
          : <String, dynamic>{};

      final tStatusId = int.tryParse(
        (tStatusMap['id'] ?? t['status_id'])?.toString() ?? '',
      );
      final tCode =
          (tStatusMap['kode'] ?? _resolveStatusCode(tStatusId ?? statusId ?? 1))
              .toString()
              .toUpperCase();
      final tName =
          (tStatusMap['nama_status'] ?? AdminStatusHelper.getStatusLabel(tCode)).toString();

      return AdminDeliveryTrackingItem(
        id: int.tryParse(t['id']?.toString() ?? '0') ?? 0,
        statusId: tStatusId,
        statusCode: tCode,
        statusName: tName,
        lokasiNama: t['lokasi_nama']?.toString(),
        catatan: t['catatan']?.toString(),
        employeeName: tEmpMap['nama_lengkap']?.toString(),
        eventSource: t['event_source']?.toString(),
        latitude: double.tryParse(t['latitude']?.toString() ?? ''),
        longitude: double.tryParse(t['longitude']?.toString() ?? ''),
        createdAt: DateTime.tryParse(t['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();

    // Parse lokasi terakhir kurir dari t_shipment_locations
    AdminCourierLocationPoint? locationPoint;
    if (lastLocationMap != null) {
      final lat = double.tryParse(lastLocationMap['latitude']?.toString() ?? '');
      final lng = double.tryParse(lastLocationMap['longitude']?.toString() ?? '');
      final cId = int.tryParse(lastLocationMap['courier_id']?.toString() ?? '') ??
          int.tryParse(courierMap?['id']?.toString() ?? '') ??
          0;
      if (lat != null && lng != null) {
        locationPoint = AdminCourierLocationPoint(
          id: int.tryParse(lastLocationMap['id']?.toString() ?? '0') ?? 0,
          shipmentId: int.tryParse(lastLocationMap['shipment_id']?.toString() ?? ''),
          courierId: cId,
          latitude: lat,
          longitude: lng,
          speedMps: double.tryParse(lastLocationMap['speed_mps']?.toString() ?? ''),
          heading: double.tryParse(lastLocationMap['heading']?.toString() ?? ''),
          accuracyM: double.tryParse(lastLocationMap['accuracy_m']?.toString() ?? ''),
          recordedAt: DateTime.tryParse(
            (lastLocationMap['recorded_at'] ?? lastLocationMap['created_at'] ?? '')
                .toString(),
          ),
        );
      }
    }

    final pengirimNama = (map['pengirim_nama'] ?? '-').toString();
    final pengirimNoHp = (map['pengirim_no_hp'] ?? '-').toString();

    return AdminDeliveryDetailModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      nomorResi: (map['nomor_resi'] ?? '-').toString(),
      barcodeValue: (map['barcode_value'] ?? map['nomor_resi'] ?? '-').toString(),
      statusId: statusId,
      statusKode: statusCode,
      statusNama: statusName,
      serviceTypeId: int.tryParse(
        (serviceMap['id'] ?? map['service_type_id'])?.toString() ?? '',
      ),
      serviceKode: (serviceMap['kode'] ?? 'REG').toString(),
      serviceNama: (serviceMap['nama_layanan'] ?? 'Reguler').toString(),
      serviceEstimasi: estimasiStr,
      customerId: int.tryParse(
        (userMap['id'] ?? map['customer_id'])?.toString() ?? '',
      ),
      customerNama: (userMap['nama_lengkap'] ?? pengirimNama).toString(),
      customerEmail: (userMap['email'] ?? '-').toString(),
      customerNoHp: (userMap['no_hp'] ?? pengirimNoHp).toString(),
      pengirimNama: pengirimNama,
      pengirimNoHp: pengirimNoHp,
      pengirimAlamat: (map['pengirim_alamat'] ?? '-').toString(),
      pengirimKota: (map['pengirim_kota'] ?? '-').toString(),
      pengirimKodePos: map['pengirim_kode_pos']?.toString(),
      pengirimLatitude: double.tryParse(map['pengirim_latitude']?.toString() ?? ''),
      pengirimLongitude: double.tryParse(map['pengirim_longitude']?.toString() ?? ''),
      penerimaNama: (map['penerima_nama'] ?? '-').toString(),
      penerimaNoHp: (map['penerima_no_hp'] ?? '-').toString(),
      penerimaAlamat: (map['penerima_alamat'] ?? '-').toString(),
      penerimaKota: (map['penerima_kota'] ?? '-').toString(),
      penerimaKodePos: map['penerima_kode_pos']?.toString(),
      penerimaLatitude: double.tryParse(map['penerima_latitude']?.toString() ?? ''),
      penerimaLongitude: double.tryParse(map['penerima_longitude']?.toString() ?? ''),
      totalBeratGram: num.tryParse(map['total_berat_gram']?.toString() ?? '1000') ?? 1000,
      panjangCm: num.tryParse(map['panjang_cm']?.toString() ?? '0') ?? 0,
      lebarCm: num.tryParse(map['lebar_cm']?.toString() ?? '0') ?? 0,
      tinggiCm: num.tryParse(map['tinggi_cm']?.toString() ?? '0') ?? 0,
      totalBarang: int.tryParse(map['total_barang']?.toString() ?? '1') ?? 1,
      nilaiBarang: num.tryParse(map['nilai_barang']?.toString() ?? ''),
      catatanPengiriman: map['catatan_pengiriman']?.toString(),
      biayaPengiriman: num.tryParse(map['biaya_pengiriman']?.toString() ?? '0') ?? 0,
      biayaAsuransi: num.tryParse(map['biaya_asuransi']?.toString() ?? '0') ?? 0,
      biayaLayananTambahan:
          num.tryParse(map['biaya_layanan_tambahan']?.toString() ?? '0') ?? 0,
      diskon: num.tryParse(map['diskon']?.toString() ?? '0') ?? 0,
      totalBiaya: num.tryParse(
            (map['total_biaya'] ?? paymentMap['jumlah_bayar'] ?? '0').toString(),
          ) ??
          0,
      metodePembayaran: paymentMethod,
      statusPembayaran: paymentStatus,
      nomorPembayaran: paymentMap['nomor_pembayaran']?.toString(),
      providerPembayaran: paymentMap['provider']?.toString(),
      paidAt: paymentMap['paid_at'] != null
          ? DateTime.tryParse(paymentMap['paid_at'].toString())
          : null,
      assignmentId: int.tryParse(assignmentMap?['id']?.toString() ?? ''),
      courierId: int.tryParse(courierMap?['id']?.toString() ?? ''),
      courierNama: courierMap?['nama_lengkap']?.toString(),
      courierCode: courierMap?['employee_code']?.toString(),
      courierEmail: courierMap?['email']?.toString(),
      courierPhone: courierMap?['no_hp']?.toString(),
      assignedAt: assignmentMap?['assigned_at'] != null
          ? DateTime.tryParse(assignmentMap!['assigned_at'].toString())
          : null,
      acceptedAt: assignmentMap?['accepted_at'] != null
          ? DateTime.tryParse(assignmentMap!['accepted_at'].toString())
          : null,
      completedAt: assignmentMap?['completed_at'] != null
          ? DateTime.tryParse(assignmentMap!['completed_at'].toString())
          : null,
      assignmentNotes: assignmentMap?['catatan']?.toString(),
      lastCourierLocation: locationPoint,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      estimasiTiba: map['estimasi_tiba'] != null
          ? DateTime.tryParse(map['estimasi_tiba'].toString())
          : null,
      pickedUpAt: map['picked_up_at'] != null
          ? DateTime.tryParse(map['picked_up_at'].toString())
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.tryParse(map['delivered_at'].toString())
          : null,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.tryParse(map['cancelled_at'].toString())
          : null,
      trackingHistory: parsedTrackings,
    );
  }

  static String _resolveStatusCode(int statusId) {
    switch (statusId) {
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
}

