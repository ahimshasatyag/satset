import 'package:satset/features/admin/utils/admin_status_helper.dart';
import '../../domain/entities/admin_service_type_detail.dart';
import '../../domain/entities/admin_service_type_item.dart';

class AdminServiceShipmentUsageRecordModel
    extends AdminServiceShipmentUsageRecord {
  const AdminServiceShipmentUsageRecordModel({
    required super.shipmentId,
    required super.nomorResi,
    required super.pengirimNama,
    required super.pengirimKota,
    required super.penerimaNama,
    required super.penerimaKota,
    required super.totalBeratGram,
    required super.biayaPengiriman,
    required super.totalBiaya,
    required super.statusKode,
    required super.statusNama,
    super.createdAt,
  });

  factory AdminServiceShipmentUsageRecordModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final stMap = map['m_shipment_statuses'] is Map<String, dynamic>
        ? map['m_shipment_statuses'] as Map<String, dynamic>
        : <String, dynamic>{};

    final statusId =
        int.tryParse((stMap['id'] ?? map['status_id'])?.toString() ?? '1') ?? 1;
    final statusKode = (stMap['kode'] ?? _resolveStatusCode(statusId))
        .toString()
        .toUpperCase();
    final statusNama = (stMap['nama_status'] ??
            AdminStatusHelper.getStatusLabel(statusKode))
        .toString();

    final shipmentId = int.tryParse(map['id']?.toString() ?? '0') ?? 0;

    return AdminServiceShipmentUsageRecordModel(
      shipmentId: shipmentId,
      nomorResi: (map['nomor_resi'] ?? 'SST-$shipmentId').toString(),
      pengirimNama: (map['pengirim_nama'] ?? '-').toString(),
      pengirimKota: (map['pengirim_kota'] ?? '-').toString(),
      penerimaNama: (map['penerima_nama'] ?? '-').toString(),
      penerimaKota: (map['penerima_kota'] ?? '-').toString(),
      totalBeratGram:
          int.tryParse(map['total_berat_gram']?.toString() ?? '0') ?? 0,
      biayaPengiriman:
          num.tryParse(map['biaya_pengiriman']?.toString() ?? '0') ?? 0,
      totalBiaya: num.tryParse(map['total_biaya']?.toString() ?? '0') ?? 0,
      statusKode: statusKode,
      statusNama: statusNama,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
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

class AdminServiceTypeDetailModel extends AdminServiceTypeDetail {
  const AdminServiceTypeDetailModel({
    required super.serviceType,
    super.recentShipments = const [],
  });

  factory AdminServiceTypeDetailModel.fromData({
    required AdminServiceTypeItem serviceType,
    List<AdminServiceShipmentUsageRecord> recentShipments = const [],
  }) {
    return AdminServiceTypeDetailModel(
      serviceType: serviceType,
      recentShipments: recentShipments,
    );
  }
}

