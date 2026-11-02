import '../../domain/entities/admin_activity.dart';

import 'package:satset/features/admin/utils/admin_status_helper.dart';

class AdminActivityModel extends AdminActivity {
  const AdminActivityModel({
    required super.id,
    required super.shipmentId,
    required super.nomorResi,
    required super.statusCode,
    required super.statusName,
    required super.lokasiNama,
    required super.catatan,
    super.employeeName,
    required super.timestamp,
  });

  factory AdminActivityModel.fromMap(Map<String, dynamic> map) {
    final shipment = map['t_shipments'] is Map<String, dynamic>
        ? map['t_shipments'] as Map<String, dynamic>
        : <String, dynamic>{};

    final employee = map['m_employee'] is Map<String, dynamic>
        ? map['m_employee'] as Map<String, dynamic>
        : <String, dynamic>{};

    final status = map['m_shipment_statuses'] is Map<String, dynamic>
        ? map['m_shipment_statuses'] as Map<String, dynamic>
        : <String, dynamic>{};

    final statusCode = (status['kode'] ?? map['status_kode'] ?? 'PENDING')
        .toString()
        .toUpperCase();
    final statusName =
        status['nama_status'] ??
        status['label'] ??
        AdminStatusHelper.getStatusLabel(statusCode);

    return AdminActivityModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      shipmentId:
          int.tryParse(
            map['shipment_id']?.toString() ?? shipment['id']?.toString() ?? '0',
          ) ??
          0,
      nomorResi:
          shipment['nomor_resi']?.toString() ??
          map['nomor_resi']?.toString() ??
          'SATSET-${map['shipment_id']}',
      statusCode: statusCode,
      statusName: statusName.toString(),
      lokasiNama: map['lokasi_nama']?.toString() ?? 'Hub SatSet Delivery',
      catatan: map['catatan']?.toString() ?? 'Pembaruan status operasional',
      employeeName:
          employee['nama_lengkap']?.toString() ?? employee['nama']?.toString(),
      timestamp:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
