import '../../domain/entities/admin_delivery_item.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';

class AdminDeliveryItemModel extends AdminDeliveryItem {
  const AdminDeliveryItemModel({
    required super.id,
    required super.nomorResi,
    required super.barcodeValue,
    super.customerId,
    required super.customerNama,
    required super.customerEmail,
    required super.pengirimNama,
    required super.pengirimNoHp,
    required super.pengirimAlamat,
    required super.pengirimKota,
    required super.penerimaNama,
    required super.penerimaNoHp,
    required super.penerimaAlamat,
    required super.penerimaKota,
    super.serviceTypeId,
    required super.serviceKode,
    required super.serviceNama,
    required super.totalBeratGram,
    required super.biayaPengiriman,
    required super.totalBiaya,
    required super.metodePembayaran,
    required super.statusPembayaran,
    super.courierId,
    required super.courierNama,
    super.courierCode,
    super.courierNoHp,
    super.activeAssignmentId,
    super.statusId,
    required super.statusKode,
    required super.statusNama,
    super.createdAt,
    super.updatedAt,
  });

  factory AdminDeliveryItemModel.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? customerMap,
    Map<String, dynamic>? courierMap,
    int? activeAssignmentId,
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

    // Ekstrak data pembayaran dari t_shipment_payments
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

    final serviceTypeId = int.tryParse(
      (serviceMap['id'] ?? map['service_type_id'])?.toString() ?? '',
    );
    final serviceCode = (serviceMap['kode'] ?? 'REG').toString();
    final serviceName = (serviceMap['nama_layanan'] ?? 'Reguler').toString();

    final courierId = courierMap != null
        ? int.tryParse(courierMap['id']?.toString() ?? '')
        : null;
    final courierName = courierMap != null
        ? (courierMap['nama_lengkap'] ?? 'Kurir SatSet').toString()
        : 'Belum Ditugaskan';
    final courierCode = courierMap?['employee_code']?.toString();
    final courierPhone = courierMap?['no_hp']?.toString();

    final paymentMethod =
        (paymentMap['metode_pembayaran'] ?? map['metode_pembayaran'] ?? 'TRANSFER')
            .toString();
    final paymentStatus = (paymentMap['status_pembayaran'] ??
            (paymentMethod.toUpperCase() == 'COD' ? 'COD' : 'PAID'))
        .toString();

    final customerId = int.tryParse(
      (userMap['id'] ?? map['customer_id'])?.toString() ?? '',
    );
    final pengirimNama = (map['pengirim_nama'] ?? '-').toString();
    final customerNama =
        (userMap['nama_lengkap'] ?? pengirimNama).toString();
    final customerEmail = (userMap['email'] ?? '-').toString();

    return AdminDeliveryItemModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      nomorResi: (map['nomor_resi'] ?? '-').toString(),
      barcodeValue: (map['barcode_value'] ?? map['nomor_resi'] ?? '-').toString(),
      customerId: customerId,
      customerNama: customerNama,
      customerEmail: customerEmail,
      pengirimNama: pengirimNama,
      pengirimNoHp: (map['pengirim_no_hp'] ?? '-').toString(),
      pengirimAlamat: (map['pengirim_alamat'] ?? '-').toString(),
      pengirimKota: (map['pengirim_kota'] ?? '-').toString(),
      penerimaNama: (map['penerima_nama'] ?? '-').toString(),
      penerimaNoHp: (map['penerima_no_hp'] ?? '-').toString(),
      penerimaAlamat: (map['penerima_alamat'] ?? '-').toString(),
      penerimaKota: (map['penerima_kota'] ?? '-').toString(),
      serviceTypeId: serviceTypeId,
      serviceKode: serviceCode,
      serviceNama: serviceName,
      totalBeratGram: num.tryParse(map['total_berat_gram']?.toString() ?? '1000') ?? 1000,
      biayaPengiriman: num.tryParse(map['biaya_pengiriman']?.toString() ?? '0') ?? 0,
      totalBiaya: num.tryParse(
            (map['total_biaya'] ?? paymentMap['jumlah_bayar'] ?? '0').toString(),
          ) ??
          0,
      metodePembayaran: paymentMethod,
      statusPembayaran: paymentStatus,
      courierId: courierId,
      courierNama: courierName,
      courierCode: courierCode,
      courierNoHp: courierPhone,
      activeAssignmentId: activeAssignmentId,
      statusId: statusId,
      statusKode: statusCode,
      statusNama: statusName,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
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

